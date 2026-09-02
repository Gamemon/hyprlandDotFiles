# `local/systemd/user/` — user-level timers shipped in this dotfiles repo

A bundle of timer + service pairs that wire daily-life automation into a
`systemd --user` session. None of these are enabled by default — they are
**templates** you copy or symlink into your own `~/.config/systemd/user/`,
then `systemctl --user daemon-reload && enable --now <name>.timer`.

These live under `local/` because `.config/systemd/` is git-ignored
(machine-local state, sockets, transient timers).

## What's here

| Timer | Cadence | Runs |
|-------|---------|------|
| `cs-habit.{timer,service}` | 19:00 daily | nag notification when 0 commits today |
| `canvas-sync.{timer,service}` | 07:00 + 5 min after boot | Canvas ICS → Taskwarrior + Obsidian |
| `7shifts-remind.{timer,service}` | every 5 min | shift reminder via `7shifts remind` |
| `7shifts-week.{timer,service}` | Sun 19:00 | weekly hours/shifts summary |
| `battery-power.service` | (simple service) | AC/battery profile switcher |

The `daily-note` timer lives in the [obsidian-vault-automation
repo](https://github.com/Gamemon/obsidian-vault-automation) because the
script itself lives there.

## Install (one machine)

```bash
mkdir -p ~/.config/systemd/user
install -m 0644 local/systemd/user/* ~/.config/systemd/user/

systemctl --user daemon-reload
systemctl --user enable --now cs-habit.timer canvas-sync.timer
systemctl --user enable --now 7shifts-remind.timer 7shifts-week.timer
systemctl --user enable --now battery-power.service
```

## Verify

```bash
systemctl --user list-timers
journalctl --user -u <name>.service -b
```

## Path conventions used in ExecStart

- `%h` → `$HOME` (resolves at unit load)
- `%U` → user name
- `%t` → `XDG_RUNTIME_DIR` (always `/run/user/<uid>` for user units)
- `~`-prefixed paths are NOT expanded by systemd — always use `%h` or
  absolute paths in `ExecStart`.

## cs-habit gotcha

`cs-habit.timer` previously had a symlink in
`timers.target.wants/` pointing at `/home/ajohnson269/...` (an old account
rename leftover). Re-create the symlink as the current user:

```bash
ln -sf ~/.config/systemd/user/cs-habit.timer \
       ~/.config/systemd/user/timers.target.wants/cs-habit.timer
```