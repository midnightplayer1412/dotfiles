# Changelog

All notable changes to this dotfiles repository are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/),
grouped by date since this repo is unreleased / rolling.

## [Unreleased]

### 2026-07-06

#### Changed
- **terminal** — switched the default terminal from **ghostty to kitty**.
  Ghostty's `background-opacity` renders **intermittently opaque** on this
  NVIDIA dual-GPU box (a GTK4/Wayland alpha race — confirmed ghostty-specific;
  kitty facing the identical desktop is reliably transparent). Kitty is themed
  to match: Monaspace Neon NF @ 13, `window_padding_width 8`, block cursor,
  `background_opacity 0.5` (Hyprland `decoration:blur` supplies the frosted
  look), and the ghostty split keybinds ported (`ctrl+shift+h/j/k/l` split,
  `alt+h/j/k/l` move, `alt+enter` zoom the active split).
- **launchers** — repointed every terminal launch to kitty: `Super+Return`
  (`$terminal`), `Super+E` (`$fileManager` → `kitty yazi`), the launcher `>`
  run-command (`Commands.qml`), and the `text/plain` default handler
  (`nvim-kitty.desktop`).

#### Added
- **kitty** — new tracked `kitty/kitty.conf`, plus a Matugen
  `kitty-colors.conf` template wired into `matugen/config.toml` so kitty's
  palette regenerates on every wallpaper change (generated `kitty/theme.conf`
  is gitignored, mirroring `yazi/theme.toml`). `apply-theme.sh` then sends every
  running kitty `SIGUSR1`, so the new palette **hot-reloads live** — and with
  `dynamic_background_opacity` on, the background alpha reloads too — no restart.

#### Fixed
- **widgets** (quickshell) — the **desktop widget resize grip** now actually
  resizes. `resizeArea` mapped coordinates against the `PanelWindow` root, which
  is **not a `QQuickItem`**, so `mapToItem` threw (`"Could not convert argument 0
  … to const QQuickItem*"`) on the first line of `onPressed` — aborting before
  `resizingId` was set, so every motion event hit the guard and bailed (the grip
  silently did nothing, while body-drag worked because it never calls
  `mapToItem`). Now maps to scene coordinates via `mapToItem(null, …)`.

### 2026-07-04

#### Added
- **overview** (quickshell) — **Mission Control** now shows **live window
  previews** inside the top Spaces thumbnails (a per-window `ScreencopyView`,
  gated on `Theme.overviewLivePreviews`), falling back to the colored window
  rectangles when a capture is unavailable (e.g. NVIDIA DMA-BUF flakiness).
- **overview / settings** (quickshell) — new **Mission Control options** card in
  **Settings → Window Switcher**: a **Workspace size** slider (`missionScale`,
  0.6–1.4) that scales the Spaces bar, and a **Dynamic workspaces** toggle
  (`missionDynamic`). Both persist to `overview-config.json`.
- **overview** (quickshell) — **Dynamic workspaces** (macOS-style): the Spaces
  bar shows only the occupied workspaces (plus the active one) and an
  **Add-workspace (+)** tile that switches to the next empty workspace.
- **overview** (quickshell) — **HJKL keyboard navigation of the Spaces bar**:
  from the top window row **K** hops up into the bar, **H/L** walk the
  workspaces, **Enter** switches, **J** drops back to the windows (a two-tier
  `navZone` in `OverviewState`, inert for every other layout).
- **launcher** (quickshell) — a **hint footer** showing the prefix modes
  (`/` commands, `!` shell, `=` calc) and key actions (↵ / ⇥ / esc); the active
  mode highlights and the ↵ label adapts (open / run / copy) as you type.
- **launcher** (quickshell) — new `/` commands. **Web shortcuts**: `/gh`,
  `/yt`, `/wiki`, `/maps`, and `/chatgpt` (opens a **temporary chat** with the
  prompt prefilled). **Power / session**: `/lock` (the Quickshell lockscreen),
  `/logout`, `/suspend`, `/hibernate`, `/reboot`, `/shutdown`.
- **widgets** (quickshell) — new **desktop widget system** (`quickshell/widgets/`):
  self-contained widgets that live on a free-drag **desktop layer** (bottom
  layer, drag anywhere, positions persist, gapless flush stacks) and a
  **SUPER+W command-center dashboard** overlay. First set: **Clock**, **Calendar**,
  **System monitor** (CPU/RAM), **Weather** (open-meteo, location in Settings),
  and **Media** (MPRIS; auto-hides when nothing is playing). A `WidgetRegistry`
  catalogs widgets (adding one = a descriptor + a component), and everything
  persists to `~/.config/quickshell/widgets-config.json`.
- **widgets / settings** (quickshell) — new **Settings → Widgets** pane:
  per-widget **Desktop** / **Dashboard** toggles, a **drag-to-reorder** dashboard
  order board (same pattern as the Bar widget board), a **Weather location**
  (lat/lon) field, and a **Restore default layout** button.
- **widgets / settings** (quickshell) — **per-widget settings**: a widget declares
  an optional `settings` schema in its registry descriptor (fields of type
  toggle/enum/text/number) and the Widgets pane renders it via an inline **gear**
  expander — no per-widget UI code. **Clock** (12/24h, seconds, date), **Weather**
  (°C/°F, label, lat/lon), **System monitor** (show CPU/RAM), **Calendar** (week
  starts Mon/Sun). Values persist under `settings[id]` in `widgets-config.json`.
- **widgets** (quickshell) — desktop widgets are now **resizable** and
  **snap to a grid**: a bottom-right corner grip sets an aspect-locked per-widget
  scale (0.6–2×, persisted; content scales so text/graphics grow with the box),
  and dragging snaps to a configurable grid (Shift bypasses; a faint grid overlay
  shows during a drag). Adds a **Settings → Widgets** *Desktop placement* card
  (snap toggle + grid size); *Restore default layout* also resets scales/snap.

#### Changed
- **widgets** (quickshell) — the Weather widget's location moved from a standalone
  "Weather location" card into its **per-widget settings** (one mechanism for all
  widget config); existing coordinates migrate automatically on first load.
- **overview** (quickshell) — the Mission Control Spaces bar is now a **frosted,
  edge-to-edge glass bar** pinned to the top screen edge (an in-scene
  `MultiEffect` blur of the wallpaper, masked to a rounded-bottom band),
  replacing the centered floating card.
- **overview** (quickshell) — the Spaces bar **shrinks its tiles to fit** the
  screen width (like macOS) instead of overflowing off the edges when the
  workspace size or the workspace count is large.
- **launcher** (quickshell) — the search bar now uses a **concentric radius**
  (`launcherRadius − launcherMargin`) instead of a full pill, so its corner runs
  parallel to the panel corner; the hint footer is inset to clear the rounded
  corners.

### 2026-07-02

#### Added
- **overview / settings** (quickshell) — the **SUPER+TAB** window overview is now
  a **swappable layout**, chosen in a new **Settings → Window Switcher** pane with
  five options (each shown as a mini wireframe): **Grid** (the original centered
  2×5 workspace grid, restyled), **Dock** (a bottom MRU strip of window cards),
  **Exposé** (every window spread across the screen), **Side panel** (a vertical
  workspace column docked to the edge *opposite the bar*), and **Mission Control**
  (macOS-style). The choice persists to `overview-config.json` and the open
  overview re-renders live, backed by a new `OverviewConfig` singleton +
  dispatcher `Loader` in `Overview.qml`; an unknown/edited value falls back to
  Grid. All layouts reuse the shared `OverviewState` (MRU order, focus, geometric
  HJKL nav) and the `OverviewWindow` tile (live previews).
- **overview** (quickshell) — **Mission Control** layout: a **Spaces strip** of
  live workspace thumbnails pinned along the top, the **current workspace's
  windows spread out** below, and **drag-a-window-onto-a-Space to move it** to
  that workspace. Dragging shrinks the window into a small **proxy that tracks
  the cursor** (via a new opt-in `OverviewWindow.dragProxyLongEdge` that shrinks
  around the grab point and makes the grab point the drop hotspot), so a large
  window no longer covers the Spaces and the drop lands exactly where you point.
  Releasing **on a workspace panel** moves the window; releasing anywhere else
  cancels (snaps back).
- **overview** (quickshell) — overview layouts now paint a **wallpaper backdrop**
  (shared `OverviewBackdrop`) so the real desktop windows sitting behind the
  transparent overlay aren't shown twice — once for real and once as a live tile.
  Applied to **Mission Control**, **Grid**, and **Exposé**.
- **overview / settings** (quickshell) — the **Grid** layout is now
  **configurable**: a **size** slider (60–140%) and a **3×3 position** picker
  (center / edges / corners) in the Window Switcher pane, persisted to
  `overview-config.json`; the grid re-scales and re-positions live. The pane now
  scrolls when its content overflows.
- **overview** (quickshell) — **Exposé** tiles now carry a **workspace badge**, so
  you can tell which workspace each window lives on (Exposé aggregates windows
  from every workspace into one view).
- **overview** (quickshell) — **Dock** layout gains the **wallpaper backdrop**,
  a **workspace badge** on each card, and **auto-scroll**: when HJKL/alt-tab
  selection moves to a card scrolled off-screen, the strip scrolls to keep it in
  view.
- **overview / settings** (quickshell) — **Side panel** enhancements: a
  **wallpaper backdrop**; a configurable **edge** (**Auto** = opposite the bar,
  or force **Left**/**Right**); **auto-scroll** to the workspace holding the
  selected window; and **drag-to-move** windows between workspaces — with **edge
  auto-scroll** (drag near the top/bottom to reach off-screen workspaces) at a
  configurable **speed**. All persisted to `overview-config.json`. Drag targets
  are overlaid as direct children of the layout root because a `DropArea` nested
  in the panel's `Flickable`/`Ui.Surface` never receives dragged windows.

### 2026-07-01

#### Added
- **theme / settings** (quickshell) — a swappable **Surface style** preset
  (**Glass** / **Solid**) in Settings → Appearance that re-skins every panel in
  the shell live. **Glass** is frosted: translucent surfaces with a hairline
  border and top highlight, backed by **real compositor blur** (a Hyprland
  `layerrule` matches the `quickshell-glass` layer namespace that glass windows
  carry). **Solid** reproduces the previous flat opaque look exactly, as a
  zero-risk fallback. Colors still come from Matugen either way — the preset only
  changes translucency, never hue. A **"Blur desktop behind panels"** toggle
  gates the compositor blur. The choice persists to `ui-style.json`. Built on a
  new shared `Ui.Surface` primitive (`level: 0` panel / `level: 1` card) backed
  by a `Ui.Surfaces` token singleton — the single source of truth for the look —
  which every surface across the shell now routes through.
- **ui** (quickshell) — a shared component library so buttons, inputs, and cards
  stop being hand-rolled per file: **`Ui.Button`** (`filled` / `primary` /
  `ghost` / `danger` / `chip`, with hover / pressed / disabled / busy / active
  states), **`Ui.IconButton`** (round tile or bare glyph), **`Ui.TextField`**
  (`field` / `search`, with placeholder, focus border, left icon, clear button),
  **`Ui.Card`** (icon/glyph + title + subtitle + trailing control + body), and
  **`Ui.SelectableRow`** (selected/hover rows and nav items). Semantic by design
  — the `kind`/`variant` is chosen by meaning at the call site — and they inherit
  the Glass/Solid preset and Matugen colors automatically. New `errorText` /
  `errorContainer` Theme roles give `danger` buttons proper tokens instead of a
  hardcoded red.
- **file manager / gtk** (thunar + matugen) — Thunar as the GUI file manager
  (`Super+Shift+E`; `Super+E` stays yazi), with a new Matugen **GTK** template
  (`matugen/templates/gtk-colors.css` → `~/.config/gtk-{3,4}.0/gtk.css`) so GTK
  apps and the GTK file-chooser retint with the wallpaper alongside quickshell /
  tmux / yazi / hyprlock. Backgrounds use lifted `surface_bright` tones so the
  tint is visible in dark mode. `apply-theme.sh` quits the Thunar daemon on each
  theme change so the next window loads the fresh palette.
- **ui** (quickshell) — new `Ui.ScrollView` (scrollable column) + `Theme.scrollGutter`.
  Scrollbars now **reserve a right gutter** when content overflows, so the bar
  never overlaps content, and **auto-hide** — the bar is invisible at rest and
  fades in only while scrolling or when the pointer is over the bar strip.
  Adopted across the settings panes, connection layouts, launcher, dropdown,
  notification drawer, and wallpaper picker.

#### Changed
- **shell-wide** (quickshell) — migrated ~37 files onto the shared components,
  removing the per-file duplication (net ~430 fewer lines): every panel/card
  background now uses `Ui.Surface`, and buttons / icon-buttons / inputs / titled
  cards / nav rows across bar, launcher, notifications, the connection panels
  (wifi / bluetooth / audio / vpn), settings, and calendar now use the shared
  components. The bar background follows the Surface preset (frosted under Glass,
  its `bgOpacity` knob under Solid).
- **connection** (quickshell) — replaced the hover-hub connection UX. A single
  **Connection** bar icon (combined Wi-Fi / Bluetooth / VPN status) toggles a
  unified right-side panel holding all three together; a separate **Audio** bar
  icon (headphones glyph) toggles the audio panel. The connection panel layout is
  a swappable variant — **Tiles** (default) / **Accordion** / **Stacked** — chosen
  in Settings → Appearance (`UiStyle.connectionLayout`). Wi-Fi / Bluetooth / VPN
  were extracted into reusable sections consumed by every layout. Floating panels
  (connection, notifications, calendar, HUD) now inset around the bar via
  `BarConfig.clearance()` so they never overlay it, whatever edge it sits on.

#### Removed
- **connection** (quickshell) — the hover trigger zone, the tab hub pill, the
  per-tab drawer switching, `HubConfig` + the "Connection Hub" settings pane, and
  the bar's separate `Network` / `Volume` widgets (folded into the new Connection
  and Audio icons; saved bar layouts auto-migrate `network`→`connection`,
  `volume`→`audio`).

### 2026-06-29

#### Added
- **keyboard / settings** (quickshell + asusctl) — new **Keyboard lighting**
  card in Settings → Appearance that drives the laptop's Aura backlight from the
  Matugen theme. A master toggle plus dropdowns for **color source** (follow the
  palette accent or a custom hex with swatches), **effect** (static / breathe /
  pulse — the only effects the FX507ZU4 single-zone board supports), and
  **brightness** (off / low / med / high); **speed** appears only for breathe.
  A live preview bar shows the resulting color, dimmed to hint the brightness.
  Settings persist to `keyboard-config.json` and are applied via a new
  `hypr/scripts/apply-keyboard.sh`, the single owner of the `asusctl` command.
  `apply-theme.sh` calls it after every Matugen regenerate, so the keyboard
  re-tints in lockstep with tmux / yazi / hyprlock on every wallpaper or theme
  change. The script self-guards (no-ops if `asusctl`/`asusd` are absent or the
  feature is off), so it never breaks the theme pipeline.

#### Changed
- **settings** (quickshell) — the Keyboard lighting options use uniform
  fill-width `Ui.Dropdown`s with a fixed label column, so every dropdown is the
  same width regardless of label length.

#### Fixed
- **settings** (quickshell) — the Appearance pane's content now leaves a right
  gutter so the `Ui.ScrollBar` sits clear of the content instead of overlapping
  it (matching the Launcher pane).
- **settings** (quickshell) — the Lock Screen pane's four dropdowns (time/date
  format, input position, background source) now share a uniform width instead
  of each sizing differently.

### 2026-06-27

#### Added
- **overview** (quickshell) — the **Super + Tab** workspace overview is now
  keyboard-navigable. On open the currently-focused window is selected, and
  **H / J / K / L** (or the arrow keys) move the selection to the
  geometrically nearest window in that direction across the whole grid,
  crossing workspace cells; **Enter** focuses the selected window and closes
  the overview (**Esc** still cancels). Each tile reports its center into a
  small address-keyed registry that drives a nearest-neighbour search
  (`along + 2·perpendicular` distance), so navigation follows what you see.
  Implemented entirely in QML — no new Hyprland binds — and independent of the
  Super + Alt + Tab alt-tab, which is unchanged.

### 2026-06-18

#### Added
- **launcher / settings** (quickshell) — new **Recent apps shown** setting in
  Settings → Launcher (`maxRecents` in `launcher-config.json`, default 5,
  adjustable 1–10 via a slider). The empty-query Recent section now shows up to
  this many most-used apps instead of a hard-coded 5, in both the list-rows and
  chip-strip layouts.

#### Changed
- **launcher** (quickshell) — the Recent **chip strip** now wraps onto multiple
  rows (`Flow`) instead of laying chips out in a single non-wrapping row, so it
  stays tidy at higher recent-app counts instead of overflowing horizontally.
- **cheatsheet** (quickshell) — the Hyprland keymap now lists the
  **Super + Alt + Tab** alt-tab window switcher (hold, Tab cycles, release to
  focus), and its bind comment spells out the hold/cycle/release behaviour.
- **lock** (hyprlock) — refreshed the input-field `outer_color` / `check_color`
  from sage green (`bccf81`) to periwinkle blue (`b7c4ff`).

#### Fixed
- **settings** (quickshell) — the Launcher pane's content now leaves a right
  gutter so the `Ui.ScrollBar` sits clear of the cards/slider instead of
  hugging their edge.

### 2026-06-17

#### Added
- **lock / settings** (quickshell) — new **Hide input until typing** option in
  Settings → Lock Screen → Behavior (`hideInputUntilTyping` in
  `lock-config.json`, default off). When on, the password container stays hidden
  and fades in on the first keystroke, then fades back out once the field is
  empty and idle; it stays visible during the failure shake / attempt count and
  while authenticating. The field keeps keyboard focus throughout, so the first
  blind keystroke triggers the reveal.

### 2026-06-15

#### Added
- **wallpaper** (quickshell) — the wallpaper picker gained a **search/filter**
  field, a **shuffle-now** button, and a **cycle order** preference (**Random**
  — now never repeats the current wallpaper back-to-back — vs. **Sequential**),
  persisted to `wallpaper-state.json`. The grid now supports **keyboard
  navigation** (Down to enter the grid, arrows to move, Enter to apply, Esc to
  clear/close), **opens centered on the current wallpaper**, and shows an
  **empty state** for no results. The window is larger (6 columns) with a
  scrollbar, thumbnails **lift on hover/focus**, and the Cycle switch now uses
  the shared `Ui.Toggle`.
- **ui** (quickshell) — new shared **`Ui.ScrollBar`** design-system primitive
  (slim, outline-tinted, brighter while dragged, auto-hiding); first used by the
  wallpaper picker.

#### Changed
- **wallpaper** (quickshell) — wallpapers now sort **numerically**
  (…9, 10, …57, …100) instead of lexically (1, 10, 100, 11, …).
- **ui** (quickshell) — `Ui.ScrollBar` is applied to the scrollable views that
  can actually overflow: the notifications drawer, the launcher results, the
  `Ui.Dropdown` popup, and all Settings panes (Lock Screen, Launcher, System
  Info, Appearance) — previously these had no visible scrollbar. The
  connection-hub panels (Wi-Fi/Bluetooth/VPN/audio) are deliberately excluded:
  they live in a full-height drawer their short lists never overflow.
- **settings** (quickshell) — the Lock Screen pane's wallpaper grid now loads
  the small **cached thumbnails** (with a capped `sourceSize`) instead of
  decoding the multi-MB originals into 92×58 cells, sharing the picker's
  thumbnail cache for much lower memory use.

#### Fixed
- **ui** (quickshell) — `Ui.ScrollBar` no longer appears on views whose content
  fits (the attached-scrollbar `size` auto-binding wasn't reliable for plain
  `Flickable`s, so `AsNeeded` showed a spurious bar). Its visibility is now
  bound directly to real overflow (`contentHeight > height`) across every use
  — the Settings panes, notifications drawer, launcher, dropdown, and picker.
- **wallpaper** (quickshell) — picker thumbnails no longer **reload/flash when
  scrolling back**. With ~200 wallpapers (several GB, some GIFs >300 MB) the
  originals overflowed Qt's ~10 MB pixmap cache and were re-decoded on every
  scroll. A persistent **on-disk thumbnail cache**
  (`hypr/scripts/gen-wallpaper-thumbs.sh` → `~/.cache/quickshell/wallpaper-thumbs`,
  regenerated incrementally on scan) makes (re)decoding near-instant and keeps
  memory flat; cells fall back to the original only until a thumb is generated.

### 2026-06-13

#### Added
- **bar** (quickshell) — the status **bar is now fully configurable** from a new
  Settings → **Bar** category. Dock it to any **screen edge**
  (left/right/top/bottom) with orientation-aware widgets. A **drag-drop board**
  assigns widgets to three zones (start/center/end) and reorders within a zone,
  with a **Hidden** pool; the center zone is locked to the bar's true center so it
  never drifts when a side widget changes width. Appearance sliders tune
  **thickness**, background **opacity**, **corner radius**, and **end padding**
  (top/bottom or left/right by orientation); **Reset to defaults** restores a
  known-good baseline. New widgets join the original Workspaces / Clock / Battery:
  **System Tray** (StatusNotifierItem), **Volume** (scroll to adjust, click →
  mixer), **Network** (Wi-Fi + Bluetooth status → hub), **Resources** (CPU/RAM
  from `/proc`), **Media** (MPRIS transport with a scrolling track title), and
  **App Name** (focused window, resolved to the friendly desktop-entry name,
  ellipsised). Layout is a data-driven, reconcilable widget model in `BarConfig`,
  rendered by `BarZone`; persists to `~/.config/quickshell/bar-config.json`.
  Bar widget icons share a `Theme.barIconSize`.
- **ui** (quickshell) — `Ui.Slider` now shows a **value bubble** on hover and
  during drag that follows the knob. Normalised sliders (volume, opacity, dim)
  read as a percentage; wider ranges (thickness, radius, …) read as integers.
  Applies shell-wide — bar, lock screen, and the audio mixer.
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
- **lock / settings** (quickshell) — lock-screen password-input refinements: a
  new **input position** option (center or bottom) in Settings → Lock Screen →
  Behavior (`inputPosition` in `lock-config.json`; the field renders in the
  center stack or pinned above the identity/battery row), larger masked dots
  with letter-spacing, and the blinking caret removed (empty `cursorDelegate`,
  since a static `cursorVisible:false` is re-enabled on focus).

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
