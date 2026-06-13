# Changelog

All notable changes to this dotfiles repository are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/),
grouped by date since this repo is unreleased / rolling.

## [Unreleased]

### 2026-06-13

#### Added
- **lock** (quickshell) — a dedicated Quickshell **lockscreen** replacing
  hyprlock as the primary lock (`Super + Escape`); hyprlock kept as the
  `Super + Shift + Escape` fallback. A separate instance (`lock-screen.qml`,
  rooted at `quickshell/` so the `Theme` singleton resolves) implements the
  secure `ext-session-lock-v1` protocol via `WlSessionLock` and authenticates
  through PAM (`PamContext`, `/etc/pam.d/login`, documented `onPamMessage`
  conversation). Matugen-themed, with a large clock, MPRIS media card, battery,
  and `user@host` identity; the focused monitor shows the password field
  (auto-focused, shake + attempt count on failure). New `lock/` module:
  `LockConfig`, `LockView`, `LockContext`, `AuthField`, `Clock`, `MediaCard`,
  `BatteryPill`.
- **settings** (quickshell) — an extensible **Settings panel** (`Super +
  Backspace`) with a category sidebar; the first category, **Lock Screen**, is a
  live-preview editor (shared `LockView`) that tunes every lockscreen value —
  component toggles, background source/wallpaper/blur/dim, clock & date format,
  hidden input — and persists to `~/.config/quickshell/lock-config.json`
  (`FileView` + `JsonAdapter`). Wallpaper thumbnails lazy-load on scroll.

- **ui / settings** (quickshell) — a reusable **component design-system** with
  user-switchable styles. `Ui.Toggle` / `Ui.Slider` are dispatchers that render
  the variant selected in the global `UiStyle` singleton (`ui-style.json`);
  variants ship as plain files (toggle: Capsule/Square/Notch, slider: Thin/Thick)
  with a shared API. A new **Appearance** tab in the Settings panel switches them
  with live previews, applied shell-wide. The WiFi/Bluetooth toggles and audio
  (master + per-app) sliders were migrated onto these primitives (old
  `VolumeSlider` removed), so an Appearance change re-skins the whole shell.

- **launcher / settings** (quickshell) — a major **launcher** upgrade. App search
  is now **fuzzy** (`Matcher`) and ranked by **frecency** (`UsageStore`, persisted
  launch counts/recency); an empty query shows a **Recent** section. New modes: a
  `=` **calculator** (safe evaluator; Enter copies the result via `wl-copy`) and a
  **web-search fallback** when no app matches. Fixed a stale-selection bug (the
  highlight now resets to the top result on every query change). A new **Launcher**
  tab in the Settings panel configures the launcher **position** (bottom or
  centered), the **recents layout** (list rows or chip strip), and the
  **web-search engine** (Google default, plus DuckDuckGo / Bing / Brave). New
  `UsageStore` / `Matcher` / `LauncherConfig` singletons; persisted to
  `~/.config/quickshell/launcher-usage.json` and `launcher-config.json`.
- **ui** (quickshell) — a themed **`Ui.Dropdown`** replaces the default-system
  `ComboBox` shell-wide (Matugen colors, rounded field, Nerd Font chevron, themed
  popup list with primary-highlighted selection). Drop-in API (`model`,
  `textRole`, `currentIndex`, `activated`) covering string and object models;
  rolled out to the Lock Screen settings (time / date / source) and the wallpaper
  interval picker (removing ~90 lines of bespoke per-site combo styling).
- **connection / settings** (quickshell) — the **Connection Hub** is now
  configurable from a new **Connection Hub** tab in the Settings panel: drag the
  handle to reorder the Wi-Fi / Bluetooth / Audio / VPN tabs and toggle each on
  or off, with a live glyph preview. Order + visibility persist to
  `~/.config/quickshell/hub-config.json` (new `HubConfig` singleton); `Hub.qml`
  renders from it via a `Repeater`, and the hub hides entirely when no tabs are
  enabled. Both Settings editors now share one layout — controls on the left,
  live preview on the right — and the lock-screen preview's render is inset from
  its frame edge.
- **settings** (quickshell) — an **About** tab, pinned to the bottom of the
  Settings sidebar (below a divider, set apart from the functional tabs). A
  read-only system/hardware snapshot — OS, kernel, hostname, compositor, uptime
  (Software) and CPU + thread count, GPU(s), memory, root disk (Hardware) —
  gathered in a single `bash` pass (`Process` + `StdioCollector`) each time the
  panel opens, so values like uptime stay fresh. New `SystemInfoPane`.
- **ui / settings** (quickshell) — a new **`Ui.Icon`** primitive renders SVG/theme
  icons at an exact pixel size (`sourceSize == size`), so apparent size is
  deterministic — unlike font glyphs, which vary in drawn extent at the same
  `pixelSize`. The Settings sidebar and About pane now use **Papirus *symbolic*
  icons**, recoloured to the Matugen accent via `ColorOverlay` (the symbolic set
  is authored `fill="currentColor"`), keeping the monochrome themed look while
  fixing the icon-size inconsistency.
- **theme / settings** (quickshell) — an optional **static theme color**. By
  default the Material You palette is derived from the wallpaper; the new "Theme
  color" section in Settings → Appearance lets you instead pick a fixed **seed**
  (preset swatches or a hex field) from which Matugen derives the whole palette
  — retinting Quickshell, tmux, yazi, and hyprlock together. A new
  `hypr/scripts/apply-theme.sh` is the single Matugen entry point (static →
  `matugen color hex`, auto → `matugen image`); `apply-wallpaper.sh` now routes
  through it, so changing/cycling wallpaper honors the mode (static keeps the
  seed). New `ThemeConfig` singleton; persisted to
  `~/.config/quickshell/theme-config.json`.

#### Fixed
- **cheatsheet** (quickshell) — regenerated the Hyprland keymap so the new
  `Super + Backspace` (Settings panel) and `Super + Shift + Escape` (hyprlock
  fallback) binds appear in the cheatsheet.
- **lock** (quickshell) — the lockscreen's "current desktop" wallpaper source now
  works. `LockView` read the wallpaper-state key as `currentPath`, but
  `WallpaperService` writes it as `current`; the mismatch always resolved to an
  empty string and silently fell back to the static lock image.
- **hypr** — `autostart` now `pkill`s both `qs` and `quickshell` before
  relaunching, so a config reload can no longer leave duplicate shell instances
  (which double-registered global shortcuts).

### 2026-06-12

#### Added
- **audio** (quickshell) — per-application volume mixer in the Connection Hub's
  Audio tab. The tab is now a full mixer: a **master** slider, the existing
  **output-device** switcher, and an **Apps** section with one row per playing
  stream — app icon, live volume slider, level-aware mute, and an inline
  **output picker** to route that app to a different sink. Volume and mute bind
  directly to the native PipeWire service (`Quickshell.Services.Pipewire`, kept
  bound via `PwObjectTracker`); routing uses `pactl move-sink-input` keyed by the
  stream's `object.serial` (which pipewire-pulse uses as the sink-input index, so
  it maps directly). New `VolumeSlider.qml`, `AppVolumeRow.qml`, `AppMixer.qml`;
  `AudioPanel` restructured and made scrollable; `AudioService.moveStream` added.
- **notifications** (quickshell) — notification center enhancements:
  - **Grouping by app** — the center drawer buckets notifications under a
    per-app header with a count badge; multi-item groups collapse/expand on
    click, single notifications render bare. New `NotificationGroup.qml`; the
    list is a `Flickable` + `Repeater` over a `grouped` model (per-app collapse
    state lives in `NotificationCenterState`).
  - **Relative timestamps** — each card shows `now` / `3m` / `1h`, refreshed by
    a single `nowMs` ticker in `NotificationService` (no per-card timers).
  - **Swipe to dismiss** — drag a card either direction past a threshold to
    fling it off and remove it; releasing short snaps back. A `DragHandler`
    (yAxis disabled) composes with the existing tap targets and the drawer's
    vertical scroll. Dismissal animates the card's own `height` to 0 so the
    cards below — and the scroll area — reflow in one continuous motion; the ✕
    button routes through the same collapse.
  - **Do Not Disturb** — header bell toggle that suppresses popups while still
    collecting them into history; critical notifications still pop through.
  - **Nerd Font glyphs** — media transport (state-aware play/pause), dismiss,
    empty state, and DND all use `nf-md-*` glyphs (verified against the
    installed font), replacing the previous emoji. New `Theme.glyphFont` token.
- **cheatsheet** (quickshell) — a full-screen keybinding cheatsheet overlay,
  toggled with **Super + /** (Esc / click-outside to close). New
  `quickshell/cheatsheet/` module following the Overview pattern (a
  `CheatsheetState` singleton + a screen-gated `Variants` block in `shell.qml`):
  - **Per-app tabs** — a vertical tab strip on the left, one tab per
    application. Selecting a tab highlights that app's bound keys on a
    CSS-drawn keyboard in the primary cyan→green gradient; unbound keys stay
    dimmed. Hovering a key lifts the cap and lists its binding(s) — combo plus
    description — in a fixed detail bar that wraps for keys with several binds.
  - **Keyboard render** — beveled keycaps on a rounded chassis "deck", drawn
    entirely in QML so every key recolors with the Matugen theme and
    highlights independently (no image assets).
  - **Data-driven keymaps** — one JSON file per app under
    `cheatsheet/keymaps/` (uniform `{key, mods, category, desc, combo?}`
    schema); dropping a new file adds a tab with no code change. Ships with
    **Hyprland, nvim, tmux, ghostty, yazi**. Sequence/prefix binds (nvim
    `<leader>`, tmux `C-a`) use the optional `combo` field to show the literal
    sequence while glowing on the leading key.
  - **Hyprland keymap auto-generated** — `hypr/scripts/gen-keymap.sh` parses
    `binds.conf` into `keymaps/hyprland.json`, reading human descriptions from
    `# @cheat <Category>: <Description>` trailing comments (dispatcher-derived
    fallback otherwise), skipping submap and mouse binds. Covered by
    `hypr/scripts/test-gen-keymap.sh`.
- **mascot** (quickshell) — a big behavior expansion for the desktop pet,
  using the rest of the Aichan sprite sheet (sprite art by **Aichan**, not
  redistributed — see licensing note below):
  - **Idle personality** — at each wander stop the cat usually just stands,
    but sometimes **sits** or takes a long **nap** (cycle back to standing
    afterwards), chosen by a weighted picker.
  - **Interactions** — single-click **pets**, double-click makes it **hop**,
    a fast cursor swipe scares it into **running away** (from its centre,
    either direction), and drag still picks it up / drops it. A drag-distance
    threshold means a click is no longer misread as a drag.
  - **System reactions** — high **CPU load** makes it run (sampled from
    `/proc/stat` deltas), a **fullscreen** window makes it run to the nearest
    corner and crouch in **stealth**, and a new **notification** triggers an
    **attack** swat.
  - **Box play** — a rare idle treat: the cat jumps into a box, does a
    randomized mix of antics (paws, peeking, scanning), and jumps out — built
    fresh each time so no two visits match.

#### Changed
- **mascot** (quickshell) — internals generalized into a data-driven
  **sequence engine**: all scripted animation is now described as data in
  `MascotConfig` and driven by pure `brain.js` helpers, with `MascotSprite`
  reduced to a dumb clip player. System signals moved into a new
  `MascotSignals` singleton. `brain.js` unit coverage grew from 12 to 37
  `node:test` cases; all 24 sprite-sheet animation regions verified against
  the actual pixels.

#### Fixed
- **app icons** (quickshell) — application icons (mixer rows, notification
  cards) no longer render as a broken-icon placeholder when a name doesn't
  resolve. Icon lookups are now existence-checked (`Quickshell.iconPath(name,
  true)`) and try the app name as a second candidate, falling back to a letter
  avatar. Also added `env = QT_QPA_PLATFORMTHEME,qt6ct` to `hyprland.conf` so
  Quickshell actually uses the qt6ct icon theme (Papirus) in the Hyprland
  session — `.bashrc`/`.profile` export it, but the session never sourced them,
  so Qt fell back to a theme without those app icons.

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
- **hud** (quickshell) — output & microphone mute feedback on the volume
  OSD. The bottom-center HUD now parses the `[MUTED]` flag from
  `wpctl get-volume` and pops on a mute toggle even when the level is
  unchanged: muted output shows a crossed-speaker icon
  (nf-md-volume-off), a dimmed bar, and a "Muted" readout. The mic-mute
  key (`XF86AudioMicMute` → `@DEFAULT_AUDIO_SOURCE@`) drives a distinct
  OSD with a microphone icon and "Microphone muted" / "Microphone on"
  label.

#### Fixed
- **hud** (quickshell) — HUD no longer flashes on login. A `seeded` flag
  suppresses the OSD for the first poll cycle, so initial-state reads of
  volume / brightness / mute don't surface the pill before any user
  input.

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
