# Changelog

All notable changes to this dotfiles repository are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/),
grouped by date since this repo is unreleased / rolling.

## [Unreleased]

### 2026-06-11

#### Added
- **mascot** (quickshell) — desktop pet ("Oreo Cat"). A sprite-based cat
  roams the configured screen with gravity, can be picked up and dropped,
  and reacts to system state: low battery (curls up to sleep), new
  notifications (ears-up "alert"), and clicks (pet). New
  `quickshell/mascot/` module: a full-screen transparent layer-shell
  overlay with a click-through input mask everywhere except the sprite, so
  it floats over apps without stealing clicks. Pure movement / gravity /
  state-selection logic lives in a dependency-free `brain.js` covered by 12
  `node:test` unit tests; the QML layer (`MascotBrain`, `MascotSprite`,
  `Mascot`) consumes it. Animations play as unsliced regions of the
  licensed Aichan sprite sheet via `AnimatedSprite` (art is git-ignored,
  not redistributed). Mounted one window per screen like the bar so the
  overlay reliably lands on the configured monitor (`MascotConfig.screenName`).

### 2026-05-23

#### Added
- **bluetooth** (quickshell) — forget/unpair device. Trash icon
  (nf-md-delete) on paired-device rows opens a confirmation dialog
  before running `bluetoothctl remove`. Service exposes
  `requestForget(mac, name)` / `confirmForget(yes)`; dialog mirrors
  `PairConfirm` layout with a red-tinted destructive action.
- **bluetooth** (quickshell) — half-connected detection. Service polls
  `pactl list cards short` for `bluez_card.<mac>` alongside
  `bluetoothctl info`, so when bluez briefly reports `Connected: yes`
  at the ACL layer but AVDTP profile setup fails, the row shows
  "Connected (no audio)" in orange instead of a misleading "Connected".
  The action pill becomes "Reconnect" and chains disconnect → connect.
  "Connecting…" / "Disconnecting…" intermediate state appears while a
  one-shot is in flight. A 2.5s delayed re-poll catches late AVDTP
  drops that surface after the connect command exits.
- **audio** (quickshell) — new 4th tab in the connection hub for
  selecting audio output. Lists all `pactl` sinks (built-in / HDMI /
  bluetooth) with type-aware icons (speaker / headphones / monitor /
  bluetooth-audio) and active-port subtext. Active sink shows accent
  background + "Active" label. Click switches default sink and moves
  any playing streams to it. Hub tab icon mirrors the currently-active
  output so audio routing is visible at a glance.

#### Changed
- **connection hub** (quickshell) — `Theme.hubWidth` bumped 140 → 188
  and `hubTriggerWidth` 180 → 220 to fit the new audio tab without
  cramping the existing icons.

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
- **Notifications** (quickshell) — popups and drawer now render the
  notification's icon (`image` with `appIcon` fallback that handles
  both theme names and absolute paths, or a fallback initial letter),
  action buttons as primary-tinted pill chips, and invoke the
  freedesktop `default` action on body click. Critical-urgency
  notifications get an `error`-colored border, never auto-dismiss,
  and survive "Clear all" (per-card ✕ still works). Drawer entries
  use a softer `outline` border to read as a list; popups keep the
  brighter `primary` accent. Shared card layout extracted into
  `NotificationCard.qml` and parametrized via Theme geometry tokens
  (`notifRadius`, `notifPadding`, `notifIconSize`, etc.).

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
