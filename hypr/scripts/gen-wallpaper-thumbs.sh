#!/usr/bin/env bash
# Generate cached thumbnails for the wallpaper picker.
#
# Why: the picker has ~200 wallpapers totalling several GB (some GIFs are
# >300 MB). Qt's in-memory pixmap cache (~10 MB default) can't hold decoded
# thumbnails for all of them, so scrolling evicts them and the grid re-reads
# and re-decodes the *originals* — slow, and the cell flashes its placeholder.
# Pointing the grid at small JPG thumbnails makes (re)decoding near-instant and
# keeps memory flat, regardless of cache eviction.
#
# Usage: gen-wallpaper-thumbs.sh [SRC_DIR] [THUMB_DIR]
# Thumbs are named "<original-basename>.jpg" (basenames are unique within the
# flat wallpaper dir), so WallpaperService can predict the path without hashing.
set -euo pipefail

src_dir="${1:-/home/jp/dotfiles/wallpapers}"
thumb_dir="${2:-${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/wallpaper-thumbs}"
mkdir -p "$thumb_dir"

shopt -s nullglob nocaseglob

generated=0
for src in "$src_dir"/*.jpg "$src_dir"/*.jpeg "$src_dir"/*.png \
           "$src_dir"/*.webp "$src_dir"/*.gif; do
    base="$(basename "$src")"
    thumb="$thumb_dir/$base.jpg"

    # Skip when the thumb already exists and is at least as new as the source.
    if [[ -f "$thumb" && "$thumb" -nt "$src" ]]; then
        continue
    fi

    # "[0]" takes the first frame of an animated GIF; -thumbnail strips metadata
    # and is faster than -resize. "^" fills the 400x400 box so the picker's
    # PreserveAspectCrop has pixels to work with on any aspect ratio.
    if magick "${src}[0]" -auto-orient -strip -thumbnail '400x400^' \
        -quality 82 "$thumb" 2>/dev/null; then
        generated=$((generated + 1))
    else
        echo "gen-wallpaper-thumbs: failed for $src" >&2
    fi
done

echo "gen-wallpaper-thumbs: generated/updated $generated thumbnail(s) in $thumb_dir" >&2
