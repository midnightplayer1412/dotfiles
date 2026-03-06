#!/bin/bash

DOTFILES_DIR="$(dirname "$(realpath "$0")")"

FONT_SRC="/home/jp/.local/share/fonts/NerdFonts/Monaspace Radon/MonaspaceRadonNF-Bold.otf"
FONT_DEST="/boot/grub/fonts/monaspace_radon.pf2"

echo "Deploying GRUB config..."

sudo grub-mkfont -n "MonaspaceRadon" -s 24 -o "$FONT_DEST" "$FONT_SRC"
sudo cp "$DOTFILES_DIR/grub" /etc/default/grub
sudo mkdir -p /boot/grub/themes/custom
sudo cp "$DOTFILES_DIR/theme.txt" /boot/grub/themes/custom/theme.txt
sudo cp "$DOTFILES_DIR/main.png" /boot/grub/themes/custom/main.png
sudo cp "$DOTFILES_DIR/select_c.png" /boot/grub/themes/custom/select_c.png
# Copy font into the theme directory so GRUB can find it when loading the theme
sudo cp "$FONT_DEST" /boot/grub/themes/custom/monaspace_radon.pf2
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "Done."
