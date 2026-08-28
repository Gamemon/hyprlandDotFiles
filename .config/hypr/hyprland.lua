-- ~/.config/hypr/hyprland.lua

local terminal = "kitty"
local fileManager = "nautilus"
local menu = "wofi --show drun"

hl.config({

    env = {
        "XCURSOR_THEME,Simp1e-Catppuccin-Mocha",
        "HYPRCURSOR_THEME,Simp1e-Catppuccin-Mocha",
        "XCURSOR_SIZE,24",
        "HYPRCURSOR_SIZE,24",
        "WLR_DRM_NO_MODIFIERS,1",
        "AQ_NO_MODIFIERS,1",
        "LIBVA_DRIVER_NAME,nvidia",
        "XDG_SESSION_TYPE,wayland",
        "GBM_BACKEND,nvidia-drm",
        "__GLX_VENDOR_LIBRARY_NAME,nvidia",
        "AQ_DRM_DEVICES,/dev/dri/card2:/dev/dri/card1"
    },

    general = {
        gaps_in = 1,
        gaps_out = 1,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(4A00C4BA)", "rgba(6200C4BA)" }, angle = 45 },
            inactive_border = "rgba(1A024ABA)"
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle"
    },

    decoration = {
        rounding = 15,
        rounding_power = 1,
        shadow = {
            enabled = true,
            range = 10,
            render_power = 4,
            color = "rgba(1a1a1aee)"
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696
        }
    },

    render = { direct_scanout = false },

    scrolling = {
        fullscreen_on_one_column = true,
        column_width = 0.9,
        direction = "right"
    },

    cursor = { no_hardware_cursors = true },

    dwindle = { preserve_split = true },

    master = { new_status = "master" },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true
    },

    input = {
        kb_layout = "us",
        follow_mouse = 1,
        mouse_refocus = true,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
            disable_while_typing = false
        }
    },

    device = {
        { name = "epic-mouse-v1", sensitivity = -0.5 }
    },

    xwayland = { force_zero_scaling = true },

    plugin = {
        scrolloverview = {
            gesture_distance = 300, -- how far is the "max" for the gesture
            scale = 0.5, -- preferred overview scale
            workspace_gap = 100,
            layout = "vertical", -- vertical or horizontal
            wallpaper = 0, -- 0: global only, 1: per-workspace only, 2: both
            blur = true, -- blur only the main overview wallpaper

            shadow = {
                enabled = true,
                range = 50,
            },
        },
    },
})
hl.layer_rule({
    match = { namespace = "waybar" },
    blur = true,
    ignore_alpha = 0
})

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1
})

hl.workspace_rule({ workspace = "1", layout = "master" })
hl.workspace_rule({ workspace = "4", layout = "monocle" })
hl.workspace_rule({ workspace = "5", layout = "scrolling" })
-- =========================================================================
-- ANIMATIONS & CURVES
-- =========================================================================
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear", { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5}, {0.75, 1.0} } })
hl.curve("quick", { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
-- =========================================================================
-- AUTOSTART
-- =========================================================================
hl.on("hyprland.start", function()
    -- 1. Update environment and give systemd a moment to absorb it
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    
    -- 2. Clean up any lingering polkit agents to prevent the "already exists" lock conflict
    hl.exec_cmd("killall -9 hyprpolkitagent polkit-kde-authentication-agent-1 2>/dev/null")

    -- 3. Short delay so D-Bus is ready, then launch KDE services safely
    hl.exec_cmd("sleep 0.5 && /usr/lib/kdeconnectd")
    hl.exec_cmd("sleep 0.5 && /usr/lib/polkit-kde-authentication-agent-1")

    -- Rest of your startup items...
    hl.exec_cmd("hyprsunset")
    hl.exec_cmd("swaync & hypridle")
    hl.exec_cmd("nordvpn c chicago")
    hl.exec_cmd("linux-wallpaper-engine --no-fullscreen-pause")
    hl.exec_cmd("sleep 1.5 && ~/.config/eww/scripts/launch_hud.sh")
    --hl.exec_cmd([[[workspace 5 silent] kitty --hold -e sh -c "fastfetch -l ~/.config/fastfetch/altlogo.txt; fastfetch; fastfetch; fastfetch; fastfetch; fastfetch; fastfetch; fastfetch; fastfetch; fastfetch; fastfetch; fastfetch; fastfetch; fastfetch; fastfetch; fastfetch; fastfetch; fastfetch -l ~/.config/fastfetch/logo.txt; fastfetch; lsd; toilet --rainbow Have a good day!"]])
    hl.exec_cmd([[[workspace 5 silent] kitty --override initial_window_width=120 --override initial_window_height=40 sh -c "fortune | figlet -w 100 -f mini | cowsay -n -r | nms -f magenta; read"]])
    --hl.exec_cmd([[[workspace 2 silent] kitty sh -c "$(echo -e 'asciiquarium\nhome/escproxy/pond/bin/pond' | shuf -n 1)"]])
    hl.exec_cmd("[workspace 1 silent] obsidian")
    --hl.exec_cmd("[workspace 2 silent] spotify")
    hl.exec_cmd("[workspace 2 silent] kitty --hold -e nvim")
    hl.exec_cmd("[workspace 2 silent] kitty --hold -e fetch -l arch --infinite -s 1.5 --depth 2.0 --height 40 --box")
    hl.exec_cmd("[workspace 3 silent] kitty --hold -e taskwarrior-tui")
    --hl.exec_cmd("[workspace 4 silent] kitty --hold -e btop")
    --hl.exec_cmd("[workspace 4 silent] steam")
    hl.exec_cmd("[workspace 4 silent] kitty --hold -e cliamp --provider spotify --visualizer ClassicLED")
    hl.exec_cmd("[workspace 5 silent] kitty --override initial_window_width=40 --override initial_window_height=20 --hold -e 'tty-clock' -C 5 -b -c")
    hl.exec_cmd("[workspace 1 silent] firefox")
    hl.exec_cmd("[workspace special:magic silent] kitty --directory /home/escproxy/opencode --hold -e opencode")
    hl.exec_cmd("snappy-switcher --daemon")
    hl.exec_cmd("~/.config/eww/scripts/audio/ascii_visualizer.py &")
    hl.exec_cmd("cava -p ~/.config/cava/config")
    hl.exec_cmd("sleep 2 && waybar")
    hl.exec_cmd("hyprpm reload -n")
end)
-- =========================================================================
-- KEYBINDINGS
-- =========================================================================
hl.bind("SUPER + g", function()
    hl.plugin.scrolloverview.overview("toggle all")
end)
-- Copilot Rebind
hl.bind("SUPER + SHIFT + CONTROL + Control_R", hl.dsp.exec_cmd("notify-send 'Copilot Key Pressed'"), { release = true })

-- Main Binds (Apps)
hl.bind("SUPER + Q", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + C", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("kill -9 -1"))
hl.bind("SUPER + M", hl.dsp.exec_cmd("shutdown -h now"))
hl.bind("SUPER + Escape", hl.dsp.exec_cmd("wlogout -b 1 -c 20 -r 20 -L 1700 -R 1700 -T 325 -B 325"))
-- Apply background blur to the wlogout layer
hl.layer_rule({
    match = { namespace = "logout_dialog" },
    blur = true,
    ignore_alpha = 0.5
})
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager))
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + R", hl.dsp.exec_cmd(menu))
hl.bind("SUPER + P", hl.dsp.window.pseudo({ action = "toggle" }))
hl.bind("SUPER + SHIFT + J", hl.dsp.layout("swapwithmaster"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind("SUPER + SHIFT + P", hl.dsp.window.pin())


-- Move focus
hl.bind("SUPER + h", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + j", hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + k", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + l", hl.dsp.focus({ direction = "r" }))

-- Move windows
hl.bind("SUPER + SHIFT + j", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg swapwithmaster"))
hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "r" }))

-- Mouse splits
hl.bind("SUPER + SHIFT + mouse_up", hl.dsp.exec_cmd("hyprctl dispatch splitratio +0.1"))
hl.bind("SUPER + SHIFT + mouse_down", hl.dsp.exec_cmd("hyprctl dispatch splitratio -0.1"))

-- Utils
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind("SUPER + SHIFT + l", hl.dsp.exec_cmd("~/bin/lock.sh"))

-- Workspaces (Native Dispatchers)
for i = 1, 9 do
    hl.bind("SUPER + " .. tostring(i), hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind("SUPER + SHIFT + " .. tostring(i), hl.dsp.window.move({ workspace = tostring(i) }))
end
hl.bind("SUPER + 0", hl.dsp.focus({ workspace = "10" }))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))

-- Special workspace
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Alt tab
hl.bind("ALT + Tab", hl.dsp.exec_cmd("snappy-switcher next"))
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("snappy-switcher prev"))

-- Scroll workspaces
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse binds (Move/Resize)
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop Multimedia
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { repeating = true, locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { repeating = true, locked = true })

-- Media Controls
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Lid Switch
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("~/bin/lock.sh"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl dispatch dpms on"), { locked = true })



-- ***************************** Window Rules ******************************* --
-- Single rule (windowrule = RULE, PATTERN)
hl.window_rule({
    name = "steam-silent-startup",
    match = { 
        class = "steam",
        initial_title = "Steam" 
    },
    tile = true,
    workspace = "4 silent"
})

hl.window_rule({
    match = { 
        class = "firefox",
        title = "Picture-in-Picture" 
    },
    float = true,
    pin = true,             -- Keeps the video visible across all workspaces
})

-- ── Eww HUD Window Rules ──────────────────────────────────────
hl.window_rule({
    match = { class = "^(eww-)" },
    float = true,
    pin = true,
    border_size = 0,
    no_shadow = true,
    no_focus = true,
    no_initial_focus = true,
})
