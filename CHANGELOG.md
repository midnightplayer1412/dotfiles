# Changelog

All notable changes to this dotfiles repository are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/),
grouped by date since this repo is unreleased / rolling.

## [Unreleased]

### 2026-05-22

#### Added
- **README** — project stack overview and structure documentation.
- **yazi** — file manager config (`init.lua`, `keymap.toml`, `yazi.toml`,
  `package.toml`) and matugen-driven theme template, so the file manager
  re-themes with every wallpaper change.
- **tmux plugins** — `tmux-continuum` (auto-restore sessions every 15min)
  and `tmux-yank` (system clipboard integration), managed via tpm.
- **nvim** — `conform.lua` formatter plugin config.

#### Changed
- **hypr** — monitor configuration switched from connector names
  (`HDMI-A-1`) to EDID descriptions, so monitor rules survive connector
  renames. Per-site rules: internal panel, home (Prism+ F270i PRO 1440p),
  office (MSI MP275 E2 1080p), plus a `preferred,auto` fallback.
- **tmux** — status bar glows in the primary color while the prefix is
  armed (visual confirmation that `C-a` was received), git branch and
  clock added to status-right, `prefix r` reloads config.
- **hyprlock** — minor outer/check color refresh.

### 2026-05-21

#### Added
- **Wallpaper picker** (quickshell) — launcher-summoned popup with a dense
  5-column grid, animated GIF support, and a GIF badge per cell. Click any
  thumbnail to pin it as the active wallpaper (cycling turns off automatically);
  toggle **Cycle** to resume random rotation; interval dropdown lets you choose
  1 / 5 / 15 / 30 / 60 min. State (`current`, `cycle`, `intervalSeconds`)
  persists across restarts via `~/.config/quickshell/wallpaper-state.json`.
- **Workspace overview** (quickshell) — SUPER+TAB toggles a centered 2×5 grid
  of all workspaces. Each cell mirrors its monitor: window tiles are sized and
  positioned proportionally to the real window's `at`/`size`, with live
  `ScreencopyView` previews captured while the overview is open. Click a cell
  to jump, click a tile to focus, drag a tile across cells to move windows
  between workspaces.
- **bashrc** — initial shell rc config.

#### Changed
- **Matugen** — consolidated from split `config.toml` + `config-lock.toml` into
  a single `config.toml`. Every wallpaper change now re-themes quickshell,
  tmux, yazi, and hyprlock from the active wallpaper; yazi and hyprlock were
  previously orphaned / frozen on a stale palette.

#### Removed
- **bash wallpaper-cycle daemon** (`hypr/scripts/wallpaper-cycle.sh`) — retired
  in favour of a Quickshell-owned `Timer` inside `WallpaperService`. A one-shot
  boot-apply fires on startup so the saved wallpaper is always re-applied after
  a reboot or quickshell restart.

#### Fixed
- **hypr** — version-update patch fix.

### 2026-05-11

#### Added
- **Connection hub** (quickshell) — bar-anchored panel housing Wi-Fi,
  Bluetooth, and VPN controls. Hover the trigger zone to reveal the hub;
  click a tab to expand a drawer. Hover bridging keeps the hub visible
  while the cursor crosses between trigger and drawer.
- **Wi-Fi panel** — extracted from the legacy `wifi/Drawer` into a reusable
  `WifiPanel` mounted by the connection drawer.
- **Bluetooth** — full pair/connect/disconnect/trust/forget flow with
  `BluetoothService`, scan with 10s auto-stop, `PairConfirm` overlay for
  interactive pairing, `DeviceRow`, and an integrated panel.
- **VPN panel** — `VpnService` with NetworkManager connection toggle and
  `VpnRow` list items.
- **Theme constants** for connection hub geometry (trigger height/width,
  hub size, drawer width/radius, gaps).
- **HubTab**, **HubTrigger**, **Hub**, and shared **Drawer** components with
  Loader-based content swapping.

#### Changed
- Refactored hub window registration to use an explicit `hubWindowsChanged`
  signal instead of implicit binding gymnastics.

#### Removed
- Bar `WifiIndicator` (replaced by the connection hub's Wi-Fi tab).
- Legacy `wifi/Drawer.qml` and `wifi/WifiState.qml`.

### 2026-05-09

#### Added
- **Wi-Fi module** (quickshell) — initial scan/connect implementation.

#### Fixed
- Notification service crash that was bringing down Quickshell on certain
  notification shapes.

### 2026-05-02

#### Added
- **Ghostty** — `toggle_split_zoom` keybind.

#### Changed
- **Launcher** behavior refactor (quickshell).

### 2026-04-25

#### Added
- **Notification module** (quickshell) — popups + notification center drawer.
- **Calendar module** (quickshell) — popup calendar surfaced from the bar.
- **Media player module** (quickshell) — playback controls embedded in the
  notification center.

### 2026-04-15

#### Changed
- **Hyprland** — super key rebind (caps lock → super via `kb_options`).

### 2026-04-03

#### Added
- **tmux** — initial config.

### 2026-03-30

#### Added
- **Hyprland** — auto-cycle wallpaper setup.

### 2026-03-27

#### Changed
- **Quickshell HUD** — layout and styling refresh.

### 2026-03-22

#### Changed
- **Hyprland** — keybind for window resize.

### 2026-03-19

#### Added
- **Nvim** — undo history setup, markdown plugin keybind.

#### Changed
- **Hyprlock** — style update.
- **Ghostty** — keybind adjustments.

#### Fixed
- **Hyprland** — HDMI monitor cursor going missing on idle.

### 2026-03-18

#### Added
- **Ghostty** — initial config.

### 2026-03-11

#### Added
- **Nvim** — gitsigns plugin, markdown preview keybind mapping.

### 2026-03-09

#### Added
- **Hyprlock** — lock screen integration.
