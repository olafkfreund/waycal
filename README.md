# waycal

A three-widget Google productivity suite for **Wayland / niri**, rendered with
[Quickshell](https://quickshell.org) and driven entirely by the
[`gog`](https://github.com/) CLI — no in-app OAuth, no Google API client.

| Widget | What it shows | Toggle |
| --- | --- | --- |
| **Calendar** | always-on agenda (next N days) + full-month dashboard overlay | `Mod+C` |
| **Mail** | unread Gmail threads + detail overlay | `Mod+M` |
| **Tasks** | open Google Tasks, check to complete | `Mod+T` |

Inspired by [waylandar](https://github.com/samjoshuadud/waylandar), but the
backend is the `gog` CLI rather than a bundled Python Google-API client.

## How it works

```
niri keybind ─► qs -c waycal ipc call <target> toggle
                          │
   systemd --user: waycal.service  (EnvironmentFile → GOG_KEYRING_PASSWORD, GOG_ACCOUNT)
                          │  spawns (inherits env)
       QML Process ─► waycal-fetch <cmd>     (thin Python adapter, stdlib only)
                          │  spawns (inherits env)
                      gog --json …            (Google Calendar / Gmail / Tasks)
```

The entire frontend↔backend contract is **"a process prints a JSON array to
stdout; QML `JSON.parse`s it."** `waycal-fetch` shells out to `gog --json …`,
normalizes the result into a small uniform schema, and prints it. On failure it
prints `{"error": …, "needsAuth": …}` so a widget can show a hint instead of
crashing. No sockets, no IPC files.

### Normalized schemas
- **event** `{id, title, description, start, end, allDay, location, link, calendar}`
- **mail** `{id, threadId, from, subject, snippet, date, unread, link}`
- **task** `{id, listId, list, title, notes, due, status, link}`

## Prerequisites

- `gog` configured with at least one account (`gog auth add you@example.com`).
- A Wayland compositor with `wlr-layer-shell` (niri, Hyprland, sway, …).
- Quickshell (pulled in by the flake / home-manager module).

### The one hard requirement: gog's keyring password

`gog` stores its OAuth refresh token in a **file keyring** that needs
`GOG_KEYRING_PASSWORD` to be readable in a non-interactive process. The widgets
run non-interactively, so this **must** be supplied. The home-manager module
does it via a systemd `EnvironmentFile` secret (see below). Verify your setup:

```bash
gog auth doctor
```

## Install (NixOS flake + home-manager module)

> home-manager is consumed as a **flake module**, not the `home-manager` CLI.

```nix
# flake.nix
{
  inputs.waycal.url = "github:olafkfreund/waycal";

  # in your home-manager configuration:
  imports = [ inputs.waycal.homeManagerModules.waycal ];

  programs.waycal = {
    enable = true;
    account = "you@example.com";
    # secret file containing:  GOG_KEYRING_PASSWORD=…   (and optionally GOG_ACCOUNT=…)
    keyringPasswordFile = config.age.secrets."waycal-gog".path;

    settings = {
      agenda_days = 7;
      mail_query  = "in:inbox is:unread";
      task_lists  = "all";
    };
  };
}
```

This installs `waycal` + `quickshell`, writes the Quickshell config to
`~/.config/quickshell/waycal`, renders `~/.config/waycal/config.toml`, and starts
a **systemd --user** service (`waycal.service`) that runs `qs -c waycal` with the
keyring secret in its environment.

Then add the [niri keybinds](examples/niri-config.kdl).

## Use without the module

```bash
# run the UI directly (gog must find GOG_KEYRING_PASSWORD in the env)
nix run github:olafkfreund/waycal#  # or: nix develop, then `qs -p ./frontend`

# debug the adapter on its own
nix run github:olafkfreund/waycal#waycal-fetch -- agenda --days 7 | jq
```

Copy [`examples/config.toml`](examples/config.toml) to `~/.config/waycal/config.toml`.

## Configuration

All keys live in `~/.config/waycal/config.toml` (or `programs.waycal.settings`):

| key | default | meaning |
| --- | --- | --- |
| `account` | `""` | gog account email (`""` → `$GOG_ACCOUNT` / single token) |
| `agenda_days` | `7` | days ahead for the agenda widget |
| `agenda_max` | `50` | max agenda events |
| `calendars` | `"all"` | `"all"` or comma-separated ids/names |
| `mail_query` | `"in:inbox is:unread"` | Gmail search query |
| `mail_max` | `20` | max mail rows |
| `task_lists` | `"all"` | `"all"` or comma-separated list ids/names |
| `task_max` | `50` | max tasks per list |

## Development

```bash
nix develop          # quickshell + python3 + uv + jq + nix linters
qs -p ./frontend     # run the UI from the source tree
python backend/waycal_fetch.py agenda --days 7 | jq
python backend/waycal_fetch.py raw -- calendar events --from today --days 1   # dump raw gog JSON
```

`waycal-fetch raw -- <gog args>` prints gog's untouched JSON — handy if a field
isn't being picked up and a normalizer in `backend/waycal_fetch.py` needs a tweak.

## Roadmap (Phase 2)

- `notify-send` reminder daemon (a systemd timer running `waycal-fetch agenda`,
  independent of widget visibility).
- Live [matugen](matugen/Theme.qml.tmpl) theming (the `Theme` singleton is already
  the single source of all colors).
- Multi-account.

## Layout

```
backend/waycal_fetch.py     # the gog adapter (stdlib only)
frontend/                   # Quickshell config (shell.qml + widgets + 3 service singletons)
nix/package.nix             # build: copy + waycal-fetch wrapper
modules/home-manager.nix    # programs.waycal (config + systemd secret wiring)
matugen/Theme.qml.tmpl      # optional theming template
examples/                   # niri keybinds + sample config.toml
```

## License

MIT.
