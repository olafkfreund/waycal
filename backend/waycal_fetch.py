#!/usr/bin/env python3
"""waycal-fetch — thin adapter over the `gog` CLI for the waycal Quickshell UI.

It shells out to `gog --json …` for Google Calendar / Gmail / Tasks, then
normalizes the output into a small, uniform schema and prints a JSON array to
stdout. On any failure it prints a single object ``{"error": …, "needsAuth": …}``
instead, so the QML frontend always receives valid JSON to ``JSON.parse``.

The whole frontend<->backend contract is: *one process prints JSON to stdout*.
No sockets, no files, no disk IPC (the Waylandar pattern, kept).

Normalized schemas
------------------
event: {id, title, description, start, end, allDay, location, link, calendar}
mail:  {id, threadId, from, subject, snippet, date, unread, link}
task:  {id, listId, list, title, notes, due, status, link}

Auth note
---------
`gog` stores its refresh token in a file keyring that needs
``GOG_KEYRING_PASSWORD`` to be readable in a non-interactive process. waycal is
meant to run under a systemd --user service that supplies it via EnvironmentFile.
If it is missing, gog fails and we surface ``needsAuth: true``.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import subprocess
import sys
from pathlib import Path

try:
    import tomllib  # Python 3.11+
except ModuleNotFoundError:  # pragma: no cover - fallback for older interpreters
    tomllib = None  # type: ignore[assignment]

GOG = os.environ.get("WAYCAL_GOG_BIN", "gog")

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

DEFAULT_CONFIG: dict = {
    "account": "",          # empty -> rely on $GOG_ACCOUNT or gog's default
    "agenda_days": 7,
    "agenda_max": 50,
    "mail_query": "in:inbox is:unread",
    "mail_max": 20,
    "task_lists": "all",     # "all" or a comma-separated list of tasklist ids/names
    "task_max": 50,
    "calendars": "all",      # "all" or comma-separated calendar ids/names
}


def config_path() -> Path:
    env = os.environ.get("WAYCAL_CONFIG")
    if env:
        return Path(env)
    base = os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))
    return Path(base) / "waycal" / "config.toml"


def load_config() -> dict:
    cfg = dict(DEFAULT_CONFIG)
    path = config_path()
    if tomllib is not None and path.is_file():
        try:
            with path.open("rb") as fh:
                data = tomllib.load(fh)
            # accept either a flat table or a [waycal] section
            if isinstance(data.get("waycal"), dict):
                data = data["waycal"]
            cfg.update({k: v for k, v in data.items() if k in DEFAULT_CONFIG})
        except (OSError, tomllib.TOMLDecodeError):
            # a broken or unreadable config must not crash the widget; defaults win.
            pass
    return cfg


# ---------------------------------------------------------------------------
# gog invocation
# ---------------------------------------------------------------------------

class GogError(Exception):
    def __init__(self, message: str, needs_auth: bool = False):
        super().__init__(message)
        self.message = message
        self.needs_auth = needs_auth


_AUTH_HINTS = (
    "GOG_KEYRING_PASSWORD",
    "keyring",
    "no TTY",
    "missing --account",
    "refresh token",
    "token",
    "unauthorized",
    "auth",
    "login",
    "credentials",
)

_SECRET_RE = re.compile(
    r"(?i)(GOG_KEYRING_PASSWORD|refresh_token|password|authorization|bearer)([=:]\s*)\S+"
)


def _redact(text: str) -> str:
    """Strip anything that looks like a secret before it is shown or logged."""
    return _SECRET_RE.sub(r"\1\2[REDACTED]", text)


def safe_arg(value: str, field: str) -> str:
    """Reject config-derived values that could be misread as gog flags.

    Everything from config.toml (account, calendars, mail_query) is passed to gog
    as argv. A value beginning with '-' would be parsed as a flag rather than data
    (argument injection), so refuse it for each comma-separated token.
    """
    text = str(value)
    for token in text.split(","):
        if token.strip().startswith("-"):
            raise GogError(f"invalid {field}: value may not start with '-' ({token.strip()!r})")
    return text


def run_gog(cfg: dict, args: list[str], *, mutating: bool = False) -> object:
    """Run `gog --json <args>` and return parsed JSON (or raise GogError)."""
    cmd = [GOG, "--json"]
    account = cfg.get("account") or os.environ.get("GOG_ACCOUNT")
    if account:
        cmd += ["--account", safe_arg(account, "account")]
    if not mutating:
        cmd.append("--no-input")  # never block on a prompt for read paths
    cmd += args

    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=30,
        )
    except FileNotFoundError as exc:
        raise GogError(f"`{GOG}` not found on PATH: {exc}") from exc
    except subprocess.TimeoutExpired as exc:
        raise GogError("gog timed out after 30s") from exc

    if proc.returncode != 0:
        stderr = _redact((proc.stderr or "").strip())
        needs_auth = any(h.lower() in stderr.lower() for h in _AUTH_HINTS)
        raise GogError(stderr or f"gog exited with code {proc.returncode}", needs_auth)

    out = (proc.stdout or "").strip()
    if not out:
        return []
    try:
        return json.loads(out)
    except json.JSONDecodeError as exc:
        raise GogError(f"could not parse gog JSON: {exc}") from exc


def as_items(payload: object) -> list[dict]:
    """Coerce gog's JSON (list, or an enveloped dict) into a list of dicts."""
    if isinstance(payload, list):
        return [x for x in payload if isinstance(x, dict)]
    if isinstance(payload, dict):
        for key in (
            "items", "events", "messages", "threads", "tasks",
            "result", "results", "data", "value", "lists",
        ):
            val = payload.get(key)
            if isinstance(val, list):
                return [x for x in val if isinstance(x, dict)]
        # a single object -> wrap it
        return [payload]
    return []


# ---------------------------------------------------------------------------
# Field helpers (defensive against gog's exact field naming)
# ---------------------------------------------------------------------------

def pick(d: dict, *keys, default=None):
    for k in keys:
        if k in d and d[k] not in (None, ""):
            return d[k]
    return default


def _time_part(value):
    """Extract a time string and an all-day flag from a Google-style start/end."""
    if isinstance(value, dict):
        if value.get("dateTime"):
            return value["dateTime"], False
        if value.get("date"):
            return value["date"], True
        return None, False
    if isinstance(value, str):
        # bare YYYY-MM-DD => all-day
        is_date = len(value) == 10 and value[4] == "-" and value[7] == "-"
        return value, is_date
    return None, False


def normalize_event(ev: dict) -> dict:
    start_raw = pick(ev, "start", "startTime", "start_time", "from", "begin")
    end_raw = pick(ev, "end", "endTime", "end_time", "to", "until")
    start, all_day_s = _time_part(start_raw)
    end, all_day_e = _time_part(end_raw)
    all_day = bool(pick(ev, "allDay", "all_day", default=all_day_s or all_day_e))
    return {
        "id": str(pick(ev, "id", "eventId", "iCalUID", default="")),
        "title": pick(ev, "summary", "title", "name", default="(busy)"),
        "description": pick(ev, "description", "notes", default=""),
        "start": start,
        "end": end,
        "allDay": all_day,
        "location": pick(ev, "location", default=""),
        "link": pick(ev, "htmlLink", "link", "url", default=""),
        "calendar": pick(ev, "calendar", "calendarId", "organizer", default=""),
    }


def normalize_mail(m: dict) -> dict:
    sender = pick(m, "from", "sender", "From")
    if isinstance(sender, dict):
        sender = pick(sender, "name", "email", "address", default="")
    return {
        "id": str(pick(m, "id", "messageId", default="")),
        "threadId": str(pick(m, "threadId", "thread", "thread_id", default="")),
        "from": sender or "",
        "subject": pick(m, "subject", "title", "Subject", default="(no subject)"),
        "snippet": pick(m, "snippet", "preview", "summary", default=""),
        "date": pick(m, "date", "internalDate", "time", "Date", default=""),
        "unread": bool(pick(m, "unread", "isUnread", default=True)),
        "link": pick(m, "url", "link", "webUrl", default=""),
    }


def normalize_task(t: dict, *, list_id: str = "", list_name: str = "") -> dict:
    return {
        "id": str(pick(t, "id", "taskId", default="")),
        "listId": list_id or str(pick(t, "listId", "tasklistId", default="")),
        "list": list_name or pick(t, "list", "tasklist", default=""),
        "title": pick(t, "title", "name", "summary", default="(untitled)"),
        "notes": pick(t, "notes", "description", default=""),
        "due": pick(t, "due", "dueDate", "due_date", default=None),
        "status": pick(t, "status", default="needsAction"),
        "link": pick(t, "webViewLink", "link", "url", default=""),
    }


# ---------------------------------------------------------------------------
# Subcommands
# ---------------------------------------------------------------------------

def cmd_agenda(cfg: dict, args) -> list[dict]:
    days = args.days or cfg["agenda_days"]
    gog_args = ["calendar", "events", "--from", "today", "--days", str(days),
                "--max", str(cfg["agenda_max"])]
    gog_args += _calendar_scope(cfg)
    payload = run_gog(cfg, gog_args)
    events = [normalize_event(e) for e in as_items(payload)]
    return _sort_events(events)


def cmd_month(cfg: dict, args) -> list[dict]:
    year, month = args.year, args.month
    first = dt.date(year, month, 1)
    last = (dt.date(year + (month == 12), (month % 12) + 1, 1) - dt.timedelta(days=1))
    gog_args = ["calendar", "events",
                "--from", first.isoformat(), "--to", last.isoformat(),
                "--max", "500"]
    gog_args += _calendar_scope(cfg)
    payload = run_gog(cfg, gog_args)
    events = [normalize_event(e) for e in as_items(payload)]
    return _sort_events(events)


def cmd_mail(cfg: dict, args) -> list[dict]:
    query = safe_arg(args.query or cfg["mail_query"], "mail_query")
    payload = run_gog(cfg, ["gmail", "search", query, "--max", str(cfg["mail_max"])])
    return [normalize_mail(m) for m in as_items(payload)]


def cmd_tasks(cfg: dict, args) -> list[dict]:
    # 1) resolve task lists
    lists_payload = run_gog(cfg, ["tasks", "lists"])
    all_lists = as_items(lists_payload)
    wanted = (args.list or cfg["task_lists"]).strip()
    if wanted and wanted != "all":
        keep = {w.strip() for w in wanted.split(",")}
        all_lists = [
            l for l in all_lists
            if str(pick(l, "id", default="")) in keep
            or pick(l, "title", "name", default="") in keep
        ]
    # 2) fetch tasks per list
    out: list[dict] = []
    for l in all_lists:
        lid = str(pick(l, "id", "tasklistId", default=""))
        lname = pick(l, "title", "name", default=lid)
        if not lid:
            continue
        payload = run_gog(cfg, ["tasks", "list", lid, "--max", str(cfg["task_max"])])
        for t in as_items(payload):
            out.append(normalize_task(t, list_id=lid, list_name=lname))
    return out


def cmd_task_done(cfg: dict, args) -> dict:
    run_gog(cfg, ["tasks", "done", args.list_id, args.task_id, "--force"], mutating=True)
    return {"ok": True}


def cmd_raw(cfg: dict, args) -> object:
    """Debug helper: dump gog's raw JSON so we can verify field names."""
    return run_gog(cfg, args.gog_args)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _calendar_scope(cfg: dict) -> list[str]:
    cals = str(cfg.get("calendars", "all")).strip()
    if not cals or cals == "all":
        return ["--all"]
    return ["--calendars", safe_arg(cals, "calendars")]


def _event_sort_key(e: dict):
    s = e.get("start") or ""
    return (s == "", s)


def _sort_events(events: list[dict]) -> list[dict]:
    return sorted(events, key=_event_sort_key)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="waycal-fetch", description=__doc__)
    sub = p.add_subparsers(dest="command", required=True)

    a = sub.add_parser("agenda", help="upcoming calendar events")
    a.add_argument("--days", type=int, default=0, help="override agenda window")
    a.set_defaults(func=cmd_agenda)

    m = sub.add_parser("month", help="events for a specific month")
    m.add_argument("year", type=int)
    m.add_argument("month", type=int, help="1-12")
    m.set_defaults(func=cmd_month)

    ml = sub.add_parser("mail", help="unread Gmail threads")
    ml.add_argument("--query", default="", help="override Gmail search query")
    ml.set_defaults(func=cmd_mail)

    t = sub.add_parser("tasks", help="open Google Tasks")
    t.add_argument("--list", default="", help="'all' or comma-separated list ids/names")
    t.set_defaults(func=cmd_tasks)

    td = sub.add_parser("task-done", help="mark a task complete (mutating)")
    td.add_argument("list_id")
    td.add_argument("task_id")
    td.set_defaults(func=cmd_task_done)

    rw = sub.add_parser("raw", help="debug: dump raw gog JSON for given args")
    rw.add_argument("gog_args", nargs=argparse.REMAINDER)
    rw.set_defaults(func=cmd_raw)

    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    cfg = load_config()
    try:
        result = args.func(cfg, args)
    except GogError as exc:
        json.dump({"error": exc.message, "needsAuth": exc.needs_auth},
                  sys.stdout)
        sys.stdout.write("\n")
        return 0  # always exit 0: the contract is "valid JSON on stdout"
    except Exception as exc:  # last-resort guard; never emit non-JSON
        # Keep the JSON contract, but surface the real cause to the journal
        # (redacted) so unexpected failures are debuggable.
        import traceback
        sys.stderr.write("[waycal-fetch] " + _redact(traceback.format_exc()))
        json.dump({"error": f"{type(exc).__name__}: {exc}", "needsAuth": False},
                  sys.stdout)
        sys.stdout.write("\n")
        return 0
    json.dump(result, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
