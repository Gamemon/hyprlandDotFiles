# hyprlandDotFiles

Live dotfile mirror for my Arch + Hyprland + Waybar + eww + cava + swaylock
setup. Symlinks from `~/.config/*` into this repo so the repo IS the
configuration — every change to a tracked file is an immediate change to the
running system.

## Layout

| Path | Purpose |
|------|---------|
| `.config/hypr/` | Hyprland compositor (`hyprland.lua` is authoritative since 0.55) |
| `.config/waybar/` | Status bar config, modules, CSS, scripts |
| `.config/eww/` | HUD overlay (system stats, weather, audio visualizer) |
| `.config/swaylock/` | Catppuccin Mocha themed lock screen |
| `.config/wlogout/` | Logout / shutdown menu |
| `.config/cava/` | Audio visualizer config + shaders |
| `.config/herdr/` | Terminal workspace manager (config + plugins; runtime state stays local) |
| `.config/litellm/` | LiteLLM proxy config (env-keyed; no secrets) |
| `.config/kitty/`, `.config/nvim/`, `.config/zsh/`, … | Per-tool config |
| `bin/` | Tracked user-executable scripts (`lock.sh`, `logout.sh`) |
| `local/bin/` | User-local helpers (`battery-save` / `battery-restore`, `homelab-open`, `wonderserv-dashboard`) |
| `local/systemd/user/` | Drop-in systemd --user templates (cs-habit, canvas-sync, 7shifts, battery-power) |
| `Downloads/` | Wallpapers + screenshots |

## What's intentionally NOT tracked

See `.gitignore`. Highlights:

- `.config/systemd/` — machine-local state, sockets, transient timers
- App caches / electron stores (`.config/Code - OSS/`, `.config/Slack/`, …)
- `.config/obsidian/` — vault plugins + plugin caches
- `~/.local/state/herdr/`, `~/.herdr/`, `~/.cache/herdr/` — runtime

## Install (one machine)

```bash
git clone git@github.com:Gamemon/hyprlandDotFiles.git ~/dotfiles
# Then symlink each tracked path into ~/.config/, e.g.
ln -s ~/dotfiles/.config/hypr  ~/.config/hypr
ln -s ~/dotfiles/.config/waybar ~/.config/waybar
# … or use stow / a small symlink script.
```

## Key tooling notes

- **Hyprland 0.55+** uses the Lua config — `hyprland.lua` is canonical;
  `hyprland.conf` is archived as `.bak`.
- **Herdr** autostarts on the special workspace via `exec-once` in
  `hyprland.lua` (`kitty --class herdr -e herdr --session dev`).
- **Swaylock** config requires `=` (not spaces) for value-taking options
  on this build — see `bin/lock.sh` for a working CLI invocation.
- **Wallpaper engine** has two binaries (`linux-wallpaper-engine` GUI,
  `linux-wallpaperengine` renderer) — only the renderer animates the
  desktop; the GUI is tray-only when `minimizeOnStartup` is true.

## Daily automation cadence

The user-level timers shipped in `local/systemd/user/` (enabled with
`systemctl --user enable --now …`) hit this cadence:

```
19:00 daily   cs-habit.timer       nag when 0 commits today
07:00 + boot  canvas-sync.timer    Canvas → Taskwarrior + Obsidian
20:30 daily   daily-note.timer     (see Gamemon/obsidian-vault-automation)
every 5 min   7shifts-remind.timer shift reminder
Sun 19:00     7shifts-week.timer   weekly hours summary
always        battery-power.service AC/battery profile watcher
```