#!/bin/bash

WALLPAPER_DIR="/home/jp/dotfiles/wallpapers"
INTERVAL=60 # 5 minutes in seconds
TRANSITION_TYPE="fade"
TRANSITION_DURATION=2

while true; do
    wallpaper=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" -o -name "*.gif" \) ! -name "lock.*" | shuf -n 1)

    if [ -n "$wallpaper" ]; then
        swww img "$wallpaper" \
            --transition-type "$TRANSITION_TYPE" \
            --transition-duration "$TRANSITION_DURATION"

        # Regenerate matugen colors from the new wallpaper
        matugen image --source-color-index 0 "$wallpaper"

        # Reload tmux config to pick up new colors
        tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null
    fi

    sleep "$INTERVAL"
done
