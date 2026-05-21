# Changelog

All notable changes to this dotfiles repository are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/),
grouped by date since this repo is unreleased / rolling.

## [Unreleased]

### 2026-05-21

#### Added
- **Workspace overview** (quickshell) — SUPER+TAB toggles a centered 2×5 grid
  of all workspaces. Each cell mirrors its monitor: window tiles are sized and
  positioned proportionally to the real window's `at`/`size`, with live
  `ScreencopyView` previews captured while the overview is open. Click a cell
  to jump, click a tile to focus, drag a tile across cells to move windows
  between workspaces.
- **bashrc** — initial shell rc config.

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
