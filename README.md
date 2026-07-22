# dotfiles

Personal dotfiles for a Hyprland-based Wayland desktop on Arch Linux.

## Stack

| Component | Tool |
|-----------|------|
| Window Manager | Hyprland |
| Shell / Panel UI | Quickshell (Qt6 QML) |
| Color Generation | Matugen (Material You) |
| Editor | Neovim |
| Boot Loader | GRUB2 |

## Structure

```
dotfiles/
├── hypr/           → ~/.config/hypr
├── quickshell/     → ~/.config/quickshell
├── matugen/        → ~/.config/matugen
├── nvim/           → ~/.config/nvim
├── grub/           → /etc/default/grub (copied), /boot/grub/ (deployed)
└── wallpapers/
    └── main.jpg    — wallpaper used by Hyprland and Matugen
```

Configs are symlinked from `~/.config/` except GRUB which deploys to `/boot/` via script.

## Symlink Setup

```sh
ln -sf ~/dotfiles/hypr       ~/.config/hypr
ln -sf ~/dotfiles/quickshell ~/.config/quickshell
ln -sf ~/dotfiles/matugen    ~/.config/matugen
ln -sf ~/dotfiles/nvim       ~/.config/nvim
sudo ln -sf ~/dotfiles/grub/grub /etc/default/grub
```

---

## Hypr

Hyprland compositor config split into modular files:

- `hyprland.conf` — monitors, programs, visuals, layout
- `components/autostart.conf` — startup services
- `components/binds.conf` — keybindings
- `components/input.conf` — keyboard/mouse/gesture settings
- `touchpad.conf` — touchpad device settings (scroll/sensitivity, plus the
  `enabled = true` boot default that `apply-touchpad.sh` overrides at runtime)

**Monitors:** eDP-1 (1920x1080@144) + HDMI-A-1 (2560x1440@144)
**Layout:** Dwindle
**Borders:** Animated cyan/green gradient (active), grey (inactive)

**Key bindings (Super = mainMod):**

| Key | Action |
|-----|--------|
| Super + Return | Terminal (kitty) |
| Super + E | File manager (yazi in kitty) |
| Super + Shift + E | GUI file manager (Thunar) |
| Super + Space | Launcher |
| Super + Q | Close window |
| Super + 1-0 | Switch workspace |
| Super + Shift + 1-0 | Move window to workspace |
| Super + Arrow keys | Move focus |
| Super + C | Toggle float & center |
| Super + / | Keybinding cheatsheet |
| Super + N | Notification center |
| Super + W | Widget dashboard |
| Super + Y | Lyrics strip (toggle) |
| Super + Shift + Y | Full-screen karaoke lyrics |
| Super + Backspace | Settings panel |
| Super + Shift + T | Toggle touchpad |
| Super + Escape | Lock screen (Quickshell) |
| Super + Shift + Escape | Lock screen (hyprlock fallback) |

---

## Quickshell

Qt6 QML-based UI shell. Entry point: `shell.qml`.

**Components:**
- **Bar** — A fully configurable panel. Dock it to any **screen edge**
  (left / right / top / bottom); every widget is orientation-aware. A Settings →
  **Bar** drag-drop board places widgets across three zones (start / center / end,
  plus a **Hidden** pool) and reorders within a zone — and the center zone stays
  locked to the bar's true center so it never drifts. Appearance sliders set
  thickness, background opacity, corner radius, and end padding, with **Reset to
  defaults**. Widgets: Workspaces, Clock, Battery, **System Tray**, **Volume**
  (scroll / click → mixer), **Network** (Wi-Fi + Bluetooth → hub), **Resources**
  (CPU / RAM), **Media** (MPRIS transport with a scrolling title), and **App
  Name** (focused window). Persists to `~/.config/quickshell/bar-config.json`.
- **Launcher** — Search panel (`Super + Space`) with **fuzzy** app search ranked
  by **frecency** (your most-used float up). Modes: `/` commands, `!` shell, `=`
  calculator (Enter copies the result), and a **web-search** fallback when nothing
  matches. **Four selectable layouts**, chosen live in Settings → **Launcher**:
  **Compact bar** (small, bottom or centered), **Spotlight** (centered card, S/M/L
  size), **Edge sidebar** (full-height, left/right, narrow/medium/wide), and **App
  grid** — a full-screen macOS-Launchpad-style grid that shows every app paged
  (fixed 5 rows × 5–8 columns) with **swipe / wheel / arrow-or-`Ctrl+HJKL`** paging
  and page dots. The three list layouts share a **Recent** section/strip on the
  empty query; the grid shows all apps. Per-layout options (position, size, edge,
  columns, icon size, labels), plus shared recents count and web-search engine
  (Google / DuckDuckGo / Bing / Brave). Persists to
  `~/.config/quickshell/launcher-*.json`.
- **Overview / Window Switcher** — Full-screen window overview (`Super + Tab`)
  with **five swappable layouts**, chosen live in Settings → **Window Switcher**:
  **Grid** (workspace mini-monitors; configurable size + a 9-preset position),
  **Dock** (a bottom most-recently-used strip of window cards), **Exposé** (every
  window across all workspaces, each badged with its workspace), **Side panel** (a
  vertical workspace column docked **Left / Right / Auto**, with drag-to-move
  between workspaces and edge auto-scroll at a configurable speed), and **Mission
  Control** (macOS-style — a Spaces strip on top, the current workspace's windows
  below, drag a window onto a Space to move it via a cursor-tracking proxy). All
  layouts share live window previews, **HJKL / arrow** navigation, workspace-aware
  **drag-and-drop**, and a wallpaper backdrop so windows aren't shown twice. A
  separate hold-to-cycle alt-tab (`Super + Alt + Tab`, MRU order, release to
  focus) reuses the same engine. Persists to
  `~/.config/quickshell/overview-config.json`.
- **Desktop widgets** — Self-contained widgets on a free-drag **desktop layer**
  (drag anywhere, positions persist, gapless flush stacks). Each is **resizable**
  via a corner grip (aspect-locked per-widget scale, 0.6–2×) and **snaps to a
  grid** while dragging (Shift bypasses). Plus a **SUPER+W command-center
  dashboard** overlay. First set: **Clock**, **Calendar**, **System monitor**,
  **Weather** (open-meteo), and **Media** (auto-hides when nothing plays). A
  `WidgetRegistry` makes adding a widget a two-step change. **Settings → Widgets**
  has per-widget Desktop/Dashboard toggles, a drag-to-reorder dashboard order, a
  **Desktop placement** card (snap toggle + grid size), a weather location field,
  and restore-to-default; persists to `~/.config/quickshell/widgets-config.json`.
- **Lyrics strip** — An edge-docked **synced-lyrics** overlay that appears while
  media plays. Dock it to the **top or bottom** edge; it follows the shared
  Solid/Glass surface theme (or goes fully **transparent** — just outlined text),
  is **click-through** (pointer passes straight through), dodges the bar, and
  rounds only the corners facing into the screen. Three layouts — **Single**,
  **Triple**, and **Scroll** — chosen live; plain (untimed) lyrics fall back to
  the scroll view with an **"unsynced"** badge, and instrumental passages show
  pulsing dots. Lyrics resolve from **local `.lrc`** (a sidecar next to the track,
  or an `Artist - Title.lrc` in a configured folder) first, then **LRCLIB**
  online with a disk cache — so a song stays offline after its first fetch (misses
  cache too, with a 7-day self-heal). `Super + Y` toggles the strip; `Super +
  Shift + Y` opens a **full-screen karaoke** overlay where the sheet glides up
  line by line and the active line swells into the center. **Settings → Widgets →
  Lyrics strip** (gear to expand) sets placement/screen, layout, transparent
  background, font size & strip height, local-file source + folder, **Clear
  cache** / **Save `.lrc`**, and behavior (slide animation, auto-hide when paused,
  sync offset). Persists to `~/.config/quickshell/lyrics-config.json`.
- **HUD** — Right-edge panel, volume and brightness sliders (auto-hide)
- **Connection Hub** — Top-right drawer with Wi-Fi / Bluetooth / Audio / VPN
  tabs. The **Audio tab** is a full mixer: a master slider, output-device
  switching, and a **per-app volume mixer** — each playing app gets a live
  slider, mute, and an inline picker to route it to a different output. Volume
  and mute bind directly to the native PipeWire service (`Quickshell.Services.
  Pipewire`); routing uses `pactl move-sink-input`. Which tabs appear and their
  order are configurable in the Settings panel (drag to reorder, toggle to
  show/hide); persisted to `~/.config/quickshell/hub-config.json`.
- **Notifications** — Popup toasts plus a right-side center drawer (`Super + N`)
  with an MPRIS media player. Notifications are **grouped by app** (collapsible,
  with a count badge), show a relative **timestamp**, and can be **swiped away**
  (drag in either direction; the slot collapses as the card leaves). A header
  **Do Not Disturb** toggle silences popups while still collecting history
  (critical notifications still pop through).
- **Cheatsheet** — Full-screen keybinding overlay (`Super + /`). Per-app tabs
  (Hyprland, nvim, tmux, kitty, yazi) highlight each app's bound keys on a
  CSS-drawn keyboard; hover a key to see its binding in the detail bar.
  Keymaps are JSON files under `cheatsheet/keymaps/` (one per app); the
  Hyprland map is generated from `binds.conf` by `hypr/scripts/gen-keymap.sh`,
  which runs from `autostart.conf` as `exec =` on every reload so the sheet
  can't drift from the real binds. It is deliberately ordered *above* the
  quickshell relaunch line: `KeymapData` reads the JSON once at startup with no
  file watching, so a shell that started first would show the previous keymap.
- **Lock Screen** — A dedicated, secure lock instance (`lock-screen.qml` →
  `qs -p … lock-screen.qml`) implementing the `ext-session-lock-v1` protocol
  (`WlSessionLock`) with real PAM authentication (`/etc/pam.d/login`). Themed
  via Matugen, with a large clock, MPRIS media controls, battery, and user
  identity. Every value (components shown, wallpaper/blur/dim, clock & date
  format, password-input position — center or bottom — and hidden input) is
  read from `~/.config/quickshell/lock-config.json`.
  hyprlock is kept installed as a `Super + Shift + Escape` fallback.
- **Settings panel** (`Super + Backspace`) — An extensible settings app with a
  category sidebar. **Appearance** lets you switch the active style variant for
  shared UI components (toggle: Capsule / Square / Notch; slider: Thin / Thick)
  with live previews — the choice is global and re-skins every component across
  the shell instantly. It also sets the **theme color** — keep Matugen's
  wallpaper-derived palette, or pick a fixed seed color (swatch or hex) that
  retints the whole shell plus tmux/yazi/hyprlock. **Bar** configures the status
  bar — screen edge, appearance (thickness / opacity / radius / padding), and a
  drag-drop widget layout, with reset-to-defaults. **Lock Screen** is a
  live-preview editor that tunes the
  lockscreen config and persists it (lazy-loaded wallpaper grid). **Connection
  Hub** lets you drag to reorder the hub tabs and toggle each on/off, with a live
  glyph preview. **Launcher** picks the launcher layout (compact bar / spotlight /
  edge sidebar / app grid, with a mockup of each) and its per-layout options,
  recents layout, and web-search engine. **Window Switcher** picks the overview layout (with a mini
  wireframe of each) and its per-layout options — Grid size/position, Side panel
  edge and drag auto-scroll speed. **Input** holds the touchpad master switch,
  which shares its state file with the `Super + Shift + T` bind (see Touchpad
  below), so toggling from the keyboard moves the switch live.
  **About** (pinned to the bottom of the sidebar) shows a
  read-only system/hardware snapshot — OS, kernel, host, compositor, uptime,
  CPU, GPU(s), memory, disk — gathered live each time the panel opens. New
  categories drop into `settings/categories/`.
- **UI design-system** (`ui/`) — Reusable, themed primitives. `Ui.Toggle` and
  `Ui.Slider` are **dispatchers**: each renders whichever variant is selected in
  the `UiStyle` singleton (`~/.config/quickshell/ui-style.json`), so any
  component using them follows the global Appearance setting. Variants are plain
  files (`ToggleCapsule/Square/Notch`, `SliderThin/Thick`) sharing one API —
  adding a style is one file + one line. Sliders show a **value bubble** on
  hover/drag (a percentage for 0–1 sliders, an integer otherwise). `Ui.Dropdown`
  is a single themed
  dropdown (Matugen colors, Nerd Font chevron, themed popup list) that replaces
  the system `ComboBox` shell-wide. Consumed by the Settings panel, the
  WiFi/Bluetooth toggles, audio sliders, and the wallpaper picker. `Ui.Icon`
  renders SVG/theme icons at an exact size (so they never vary the way font
  glyphs do) and optionally recolors them to the accent — used by the Settings
  sidebar and About pane with Papirus *symbolic* icons.
- **Mascot** — Sprite-based desktop pet ("Oreo Cat") that roams the screen
  with gravity. Wanders with occasional sit/nap idles and a rare box-play
  routine; reacts to clicks (pet / hop), a fast cursor swipe (run away),
  low battery (sleep), high CPU (run), fullscreen (hide in a corner), and
  notifications (attack). Pure behavior/physics logic lives in a
  dependency-free `brain.js` with `node:test` coverage. See
  [the mascot README](quickshell/mascot/README.md).

**Theme system:**
`Theme.qml` loads colors from `~/.config/quickshell/theme/colors.json` (generated by Matugen) and watches the file for real-time updates. Entire UI recolors dynamically when the wallpaper changes. Colors come from the wallpaper by default, or from a fixed **static seed color** set in Settings → Appearance — `hypr/scripts/apply-theme.sh` is the single Matugen entry point (`matugen color hex` for static, `matugen image` for auto) so the four templates (Quickshell, tmux, yazi, hyprlock) stay in sync.

---

## Matugen

Generates Material You colors from the wallpaper.

**Workflow:**
1. Hyprland autostarts `matugen image ~/dotfiles/wallpapers/main.jpg`
2. Matugen runs the template at `matugen/templates/quickshell-colors.json`
3. Outputs `~/.config/quickshell/theme/colors.json`
4. Quickshell picks up the file change and recolors live

To manually regenerate colors:
```sh
matugen image ~/dotfiles/wallpapers/main.jpg
```

---

## Nvim

Neovim config using lazy.nvim. Entry point: `init.lua`.

**Structure:**
```
nvim/
├── init.lua
└── lua/config/
    ├── core/          — options, keymaps
    ├── lazy.lua       — plugin manager
    └── plugins/       — per-plugin config files
```

**LSP servers (auto-installed via Mason):**
`lua_ls`, `intelephense`, `html`, `emmet_ls`, `cssls`, `ts_ls`, `pyright`, `clangd`, `qmlls`

**Key bindings (Leader = Space):**

| Key | Action |
|-----|--------|
| jk | Escape (insert mode) |
| Leader + ee | File tree (Neo-tree) |
| Leader + sv/sh | Split vertical/horizontal |
| Leader + y | Yank to system clipboard |
| Ctrl+D / Ctrl+U | Scroll (cursor centered) |

---

## GRUB

Custom GRUB theme with `main.png` background and Monaspace Neon font.

**Files:**
- `grub` — `/etc/default/grub` config (copied by deploy script)
- `theme.txt` — boot menu styling (deployed to `/boot/grub/themes/custom/`)
- `main.png` — boot screen background (deployed to `/boot/grub/themes/custom/main.png`)
- `deploy.sh` — deploys all GRUB files and regenerates config

**Deploy** (run after any change to grub files):
```sh
bash ~/dotfiles/grub/deploy.sh
```

The deploy script compiles the Monaspace Neon font (size 24) to GRUB's `.pf2` format, copies all files to `/boot/grub/themes/custom/`, and runs `grub-mkconfig`.

> `/boot` is on a separate FAT32 partition so symlinks from home are not possible — deploy script is used instead.

---

## Touchpad

The built-in trackpad can be switched off from two places that share one state
file, `quickshell/touchpad-config.json`:

- **`Super + Shift + T`** → `hypr/scripts/toggle-touchpad.sh` — flips the state,
  applies it, and fires a `notify-send` card
- **Settings → Input** → `TouchpadConfig` — the same state via a `Ui.Toggle`

Neither surface calls `hyprctl` itself. Both delegate to
`hypr/scripts/apply-touchpad.sh`, the single owner of the
`hyprctl keyword device[…]:enabled` command (the rule `apply-keyboard.sh`
follows for `asusctl`). It discovers touchpads from `hyprctl -j devices` rather
than hardcoding the ASUS device string, and no-ops safely when jq, hyprctl, the
config, or a touchpad is missing — a corrupt config falls back to *enabled*, so
a bad state file can never strand you without a pointer.

**Persistence** is the `exec =` line in `autostart.conf` (not `exec-once`): it
runs at login *and* on every config reload. `touchpad.conf` always declares
`enabled = true` as the boot default, so without that line `Super + Shift + R`
would silently re-enable a touchpad you had turned off.

`hypr/scripts/test-touchpad-toggle.sh` covers the round trip, the corrupt-config
fallbacks, device discovery, and idempotency, stubbing `hyprctl`/`notify-send`
so it runs without a Hyprland session.

> Note: `jq '.enabled // true'` is wrong here — `//` treats `false` as empty, so
> a disabled touchpad reads back as enabled and the toggle becomes one-way. Both
> scripts use an explicit `type == "boolean"` check instead.

---

## Wallpaper

`wallpapers/` holds the rotation (static images plus animated GIFs). GRUB uses its own `grub/main.png`.

- **awww** — desktop background on all outputs, animated GIFs included (`awww-daemon`, started from `hypr/components/autostart.conf`)
- **Quickshell** — the picker (`Super+W`) and the auto-cycle, state in `quickshell/wallpaper-state.json`
- **Matugen** — color scheme source, re-derived from whichever wallpaper is applied
- **GRUB** — `grub/main.png` (separate file, deployed to `/boot/grub/themes/custom/`)

To change the desktop wallpaper, use the picker or drop a file into `wallpapers/`; `apply-wallpaper.sh` sets it via awww and regenerates the Matugen-driven themes.
To change the GRUB background, replace `grub/main.png` and run `bash ~/dotfiles/grub/deploy.sh`.

### GIF frame cache

awww caches whole *pre-decoded* animations under `~/.cache/awww/<version>/` — every frame, scaled and cropped to a specific output resolution. That makes re-displaying a GIF instant but is expensive: this cache once reached **77 GB**. It is now bounded.

- **Cap:** `cacheCapGb` in `quickshell/wallpaper-state.json` (default **25**). That is the only knob.
- **`hypr/scripts/awww-reap.sh`** — LRU eviction, oldest-first, never evicting the current wallpaper or anything queued.
- **`hypr/scripts/awww-prefetch.sh`** — decodes upcoming GIFs *invisibly* against a transient headless output, so bounding the cache does not reintroduce stalls.
- **`hypr/scripts/awww-cache-lib.sh`** — shared library (cache keys, usage journal). Tests: `test-awww-cache.sh`, `test-awww-reap.sh`.

Only GIFs are cached; static wallpapers cost nothing. Cache size tracks **frame count**, not source resolution — awww scales before caching, so trimming a long GIF's frames is the only per-file lever.

> **Do not add `--format bgr`/`rgb` to `awww-daemon`.** The 3-channel formats really are 3/4 the memory, but this compositor rejects them and the daemon core-dumps on startup, leaving no wallpaper at all. See `hypr/components/autostart.conf`.

---

## Credits

- **Mascot sprite art** — the "Oreo Cat" desktop pet uses the **Aichan** cat
  sprite sheet by **Aichan**. The art is not redistributed here (git-ignored
  per its license); see [`quickshell/mascot/README.md`](quickshell/mascot/README.md)
  for attribution, licensing, and where to place the sheet.
