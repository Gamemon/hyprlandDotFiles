# EWW Config 

───────────────────────────────────────────────  
 °˖* ૮( • ᴗ ｡)っ🍸 shheersh - Dionysus vers. 1.0   
 ───────────────────────────────────────────────  

## Custom animated **EWW*. 
A custom **eww (Elkowar’s Wacky Widgets) HUD** for Linux — this is duct-taped together ASCII art, system stats, network monitoring, and neon reactor-core vibes. 

![Eww Demo Png](../../assets/demo-eww.png)
---

## Features
  - Custom ASCII visualizer
  - Easy monitor of sensors and network
  - Атмосфера холодного цеха

![Eww Demo Gif](../../assets/demo-eww.gif)
  
```
eww/
├── README.md
├── demo.gif
├── demo.png
├── eww-state.yml
├── eww.scss
├── eww.yuck
├── scripts/
│   ├── ascii/
│   │   └── ascii_core_layout.sh
│   ├── audio/
│   │   ├── audio_cava_status.sh
│   │   └── audio_visualizer.py
│   ├── audio_visualizer.py
│   ├── bar/
│   │   └── bar_render.sh
│   ├── net/
│   │   ├── net_download.sh
│   │   ├── net_download_bar.sh
│   │   ├── net_ping.sh
│   │   ├── net_ping_latency.sh
│   │   ├── net_upload.sh
│   │   ├── net_upload_bar.sh
│   │   ├── net_vpn.sh
│   │   └── net_vpn_bar.sh
│   └── sys/
│       ├── sys_cpu_voltage.sh
│       ├── sys_dc_voltage.sh
│       ├── sys_fan_bar.sh
│       ├── sys_fan_spin.sh
│       ├── sys_gpu_voltage.sh
│       └── sys_workspace.sh
└── windows/
    ├── ascii/
    │   ├── audio_status.yuck
    │   └── visualizer_window.yuck
    ├── bar/
    │   └── cpu_ram_storage_bars.yuck
    ├── misc/
    │   └── welcome_text.yuck
    ├── net/
    │   ├── ascii_decor_frame.yuck
    │   ├── net_bars.yuck
    │   └── right_internet_text.yuck
    └── sys/
        ├── active_workspace.yuck
        ├── four_boxes.yuck
        ├── orange_workspace.yuck
        ├── power_cooling_header_text.yuck
        ├── power_mode_text.yuck
        ├── right_fan_data.yuck
        └── workspace_window_text.yuck
```
 

## Requirements
  - **eww** (Elkowar’s Wacky Widgets)  
  - **jq** (for JSON parsing)  
  - **lm-sensors** (for voltages, temps, fans)  
  - **nvidia-smi** (if using NVIDIA GPU monitoring)  
  - **curl**  
  - **ping**  
  - **cava**

---

## Usage
To launch the full HUD:

```
eww open-many active_workspace \
               ascii_decor_frame \
               audio_status \
               cpu_ram_storage_bars \
               four_boxes \
               net_bars \
               orange_workspace \
               power-cooling_header_text \
               power_mode_text \
               right_fan_data \
               right_internet_text \
               visualizer_window \
               welcome_text \
               workspace_window_text
```   
Add to your hyprland conf           
```      
## Auto run via hyprland
exec-once = ~/.config/eww/scripts/audio/ascii_visualizer.py &
exec-once = cava -p ~/.config/cava/config &
```   
Eww via: [waybar_watcher.sh](../hypr/scripts/waybar_watcher.sh)
Run as a `systemd` unit for more robust use.

### Configuration Notes
Voltages & temps rely on lm-sensors. Run sensors-detect once.
GPU stats require nvidia-smi.
Network assumes wlp4s0 — change your interface name in net_* scripts.
VPN detection looks for 10.6.0.x (NordVPN via strongSwan). Adjust if using another provider.

I'm sorry in advance. God speed if you try and get this running yourself. 

