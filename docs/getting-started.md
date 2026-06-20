---
layout: default
title: Getting started
tagline: From zero to three live widgets on your niri desktop.
permalink: /getting-started/
---

This guide takes you from nothing to a working waycal install: the prerequisites,
the one piece of authentication you must set up, a declarative NixOS install, the
keybinds, and a handful of real-life examples.

## Prerequisites

- A Wayland compositor that implements `wlr-layer-shell` (niri, Hyprland, sway).
- The `gog` CLI, configured with at least one Google account.
- Quickshell. The Nix flake and home-manager module pull this in for you.

Check that `gog` itself works first. Everything else depends on it.

```bash
gog auth add you@example.com     # one-time browser OAuth, stores a refresh token
gog --json calendar events --from today --days 1
```

If that prints JSON, the hard part is already done.

## The one thing you must set up: the keyring password

`gog` keeps its OAuth refresh token in a file keyring. In an interactive terminal
it can prompt you for the password to unlock it. waycal runs the widgets
non-interactively, so there is no prompt to answer. `gog` therefore needs the
password in its environment as `GOG_KEYRING_PASSWORD`.

Confirm the diagnosis with:

```bash
gog auth doctor
```

If you see a message about no TTY being available for the keyring password, that
is exactly the case waycal handles by supplying `GOG_KEYRING_PASSWORD` to the
systemd user service it runs. Keep that password in a real secret, not in your
shell history. The examples below use [agenix](https://github.com/ryantm/agenix);
[sops-nix](https://github.com/Mic92/sops-nix) works the same way.

Your secret file should contain one or two lines:

```
GOG_KEYRING_PASSWORD=your-keyring-password
GOG_ACCOUNT=you@example.com
```

## Install with the flake and home-manager module

waycal ships a flake output `homeManagerModules.waycal`. Import it as a flake
module. This is not the `home-manager` CLI; it is a module wired into your flake.

```nix
{
  inputs.waycal.url = "github:olafkfreund/waycal";

  # ... inside your home-manager configuration ...
  imports = [ inputs.waycal.homeManagerModules.waycal ];

  programs.waycal = {
    enable = true;
    account = "you@example.com";

    # the agenix/sops secret that holds GOG_KEYRING_PASSWORD (and optionally GOG_ACCOUNT)
    keyringPasswordFile = config.age.secrets."waycal-gog".path;

    settings = {
      agenda_days = 7;
      mail_query  = "in:inbox is:unread";
      task_lists  = "all";
    };
  };
}
```

Rebuild. The module installs `waycal` and Quickshell, writes the Quickshell config
to `~/.config/quickshell/waycal`, renders `~/.config/waycal/config.toml`, and
starts a systemd user service that runs `qs -c waycal` with your keyring secret in
scope. Check it came up:

```bash
systemctl --user status waycal
```

## Bind the toggles in niri

Each widget has its own IPC target, so they toggle independently. Add these to the
`binds` block in `~/.config/niri/config.kdl`.

```kdl
binds {
    Mod+C { spawn "qs" "-c" "waycal" "ipc" "call" "calendar" "toggle"; }
    Mod+M { spawn "qs" "-c" "waycal" "ipc" "call" "mail"     "toggle"; }
    Mod+T { spawn "qs" "-c" "waycal" "ipc" "call" "tasks"    "toggle"; }

    Mod+Shift+C { spawn "qs" "-c" "waycal" "ipc" "call" "calendar" "widget"; }
    Mod+Shift+R { spawn "qs" "-c" "waycal" "ipc" "call" "calendar" "refresh"; }
}
```

`toggle` opens or closes the overlay. `widget` shows or hides the always-on
desktop card. `refresh` forces an immediate re-fetch.

## Configuration

Every option lives in `~/.config/waycal/config.toml`, or in
`programs.waycal.settings` if you use the module.

| Key | Default | Meaning |
| --- | --- | --- |
| `account` | `""` | gog account email (empty uses `$GOG_ACCOUNT` or the single stored token) |
| `agenda_days` | `7` | days ahead the agenda widget shows |
| `agenda_max` | `50` | maximum agenda events |
| `calendars` | `"all"` | `"all"` or comma-separated calendar ids or names |
| `mail_query` | `"in:inbox is:unread"` | Gmail search query |
| `mail_max` | `20` | maximum mail rows |
| `task_lists` | `"all"` | `"all"` or comma-separated task list ids or names |
| `task_max` | `50` | maximum tasks per list |

## Real-life examples

### Morning triage at a glance

Open all three overlays with your keybinds, scan what is next, who emailed, and
what is due, then close them. The always-on cards keep the agenda and unread count
visible the rest of the day without any window to manage.

### Only show mail that actually needs you

The default query is everything unread. Narrow it to important, unread, primary
mail so the widget is a short list you will actually clear:

```toml
mail_query = "is:unread is:important category:primary"
```

Any Gmail search operator works here, because it is passed straight to
`gog gmail search`.

### Track a shared and a personal calendar, nothing else

If `gog calendar calendars` lists more calendars than you want on the glass, pin
the two that matter:

```toml
calendars = "primary,team-oncall@group.calendar.google.com"
```

### Complete a task without leaving the desktop

Open the tasks overlay with `Mod+T` and click the checkbox next to a task. waycal
runs `gog tasks done` for that list and task, then refreshes the list. The item
disappears. No browser, no app.

### Inspect exactly what gog returned

If a field looks wrong, ask the adapter for the raw upstream JSON and compare:

```bash
nix run github:olafkfreund/waycal#waycal-fetch -- raw -- calendar events --from today --days 1
```

The normalizers live in `backend/waycal_fetch.py`; adjusting a field is a
one-line change.

## Run it without the module

You do not need the home-manager module to try it. With `GOG_KEYRING_PASSWORD` in
your environment:

```bash
# the three widgets, straight from the source tree
nix develop github:olafkfreund/waycal
qs -p ./frontend

# or just exercise the backend
nix run github:olafkfreund/waycal#waycal-fetch -- agenda --days 7
nix run github:olafkfreund/waycal#waycal-fetch -- mail
nix run github:olafkfreund/waycal#waycal-fetch -- tasks
```

## Troubleshooting

- **A widget shows "gog needs auth".** The adapter returned `needsAuth`. The
  service cannot read the keyring. Confirm `GOG_KEYRING_PASSWORD` is in the
  service environment (`systemctl --user show-environment` and the unit's
  `EnvironmentFile`), then run `gog auth doctor`.
- **Empty widget, no error.** There may simply be nothing to show: inbox zero, a
  clear schedule, or no open tasks. Force a refresh with the `refresh` IPC call and
  check the same `gog` command by hand.
- **`gog` not found by the service.** The user service needs `gog` on its `PATH`.
  The module adds the home and per-user profile directories; if you installed
  `gog` elsewhere, add that directory.
- **Nothing renders at all.** Run `qs -p ./frontend` in a terminal and read the
  QML warnings. Quickshell prints precise file and line diagnostics.

## Where to go next

- Read the [source on GitHub](https://github.com/olafkfreund/waycal).
- The roadmap covers desktop reminder notifications and live Gruvbox theming
  through matugen; the `Theme` singleton is already the single source of all
  colors.
