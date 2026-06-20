---
layout: default
description: >-
  Calendar, Mail and Tasks widgets for Wayland and niri, rendered with Quickshell
  and driven entirely by the gog CLI.
---

<div class="hero">
  <h1>waycal</h1>
  <p class="tagline">Calendar, Mail and Tasks on your Wayland desktop, driven by one CLI.</p>
  <p class="lead">
    waycal is a set of three desktop widgets for Wayland and the
    <a href="https://github.com/YaLTeR/niri">niri</a> compositor, rendered with
    <a href="https://quickshell.org">Quickshell</a> and fed entirely by the
    <code>gog</code> Google CLI. No bundled OAuth client, no third-party service,
    no database. Your agenda, unread mail and open tasks, on the glass.
  </p>
  <div class="btn-row">
    <a class="btn btn-primary" href="{{ '/getting-started/' | relative_url }}">Get started</a>
    <a class="btn btn-ghost" href="https://github.com/olafkfreund/waycal">View source</a>
  </div>
</div>

<div class="cards">
  <div class="card">
    <h3>Calendar</h3>
    <p>An always-on agenda for the next few days, plus a full-month dashboard
    overlay you toggle with a keybind.</p>
  </div>
  <div class="card">
    <h3>Mail</h3>
    <p>Your unread Gmail threads at a glance, with a badge count and a detail
    overlay. Click to open in the browser.</p>
  </div>
  <div class="card">
    <h3>Tasks</h3>
    <p>Open Google Tasks with due dates, grouped by list. Tick the checkbox to
    complete a task in place.</p>
  </div>
</div>

## Why I built it

I live in a tiling Wayland session on niri. Panels and tray applets from the
GNOME or KDE world either do not run there or feel out of place, and I did not
want a heavyweight calendar application open all day just to answer three
questions: what is next, who emailed me, and what still needs doing.

The usual answer is a widget that talks to the Google Calendar and Gmail APIs
directly, which means embedding an OAuth client, shipping client secrets, and
maintaining a token-refresh loop inside the widget. That is a lot of surface area
for what should be a read-only glance at data I already have access to from the
terminal.

So waycal does the opposite. It owns no credentials and speaks no Google API. It
shells out to a CLI that already handles authentication, asks for JSON, and draws
it. The widget layer stays small, declarative and replaceable.

## The inspiration

Three things came together:

- **[waylandar](https://github.com/samjoshuadud/waylandar)** showed that a
  Quickshell calendar widget can be tiny if the frontend and backend talk through
  one channel: a process prints JSON to standard output and QML parses it. waycal
  keeps that contract and throws away the rest.
- **The `gog` CLI** is a single tool that already speaks Calendar, Gmail and Tasks
  with stored OAuth tokens. If one CLI covers all three Google services, then one
  widget codebase can host all three widgets with one backend pattern.
- **Gruvbox**, the same retro-warm palette behind my
  [Muninn portal](https://www.freundcloud.com/blog/introducing-muninn-my-gruvbox-github-portal/).
  Calm, legible, easy on a dark desktop.

## How it works

Everything flows through one contract: a process prints a JSON array to standard
output, and QML calls `JSON.parse` on it. There are no sockets, no IPC files and
no shared state on disk.

```
niri keybind  ->  qs -c waycal ipc call <target> toggle
                          |
   systemd user service (EnvironmentFile: GOG_KEYRING_PASSWORD, GOG_ACCOUNT)
                          |  spawns, inherits env
       QML Process  ->  waycal-fetch <cmd>      (thin Python adapter, stdlib only)
                          |  spawns, inherits env
                      gog --json ...            (Google Calendar / Gmail / Tasks)
```

`waycal-fetch` runs `gog --json ...`, normalizes the output into a small uniform
schema, and prints it. If anything fails it prints
`{"error": "...", "needsAuth": true}` instead, so a widget can show a hint rather
than crash. The QML always receives valid JSON.

The normalized shapes the widgets bind to:

| Type | Fields |
| --- | --- |
| event | `id, title, description, start, end, allDay, location, link, calendar` |
| mail | `id, threadId, from, subject, snippet, date, unread, link` |
| task | `id, listId, list, title, notes, due, status, link` |

## Design decisions worth knowing

- **The widget owns no secrets.** `gog` holds the OAuth token. waycal only ever
  reads JSON from it.
- **Three independent windows.** Each widget is its own layer-shell surface with
  its own IPC target, so you toggle calendar, mail and tasks separately and place
  them where you like.
- **One hard requirement.** `gog` stores its refresh token in a file keyring that
  needs `GOG_KEYRING_PASSWORD` to be readable by a non-interactive process. The
  home-manager module supplies it through a systemd `EnvironmentFile` secret. This
  is the one thing you must set up; the
  <a href="{{ '/getting-started/' | relative_url }}">getting started guide</a>
  walks through it.
- **Declarative install.** A Nix flake and a home-manager module install the UI,
  write the config, and run Quickshell as a user service with the secret in scope.

## Built with

Quickshell (QML), Python (standard library only), Nix flakes, home-manager, and
the `gog` CLI. MIT licensed.

<div class="btn-row">
  <a class="btn btn-primary" href="{{ '/getting-started/' | relative_url }}">Read the getting started guide</a>
</div>
