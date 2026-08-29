---------------------
---- KEYBINDINGS ----
---------------------

-- See https://wiki.hypr.land/Configuring/Basics/Binds/
--
-- Descriptions live in each bind's `desc` option, formatted "Category: Text".
-- They are real Hyprland data (exposed by `hyprctl binds -j` as .description),
-- which is what scripts/gen-keymap.sh reads to build the Super+/ cheatsheet.
-- The old hyprlang config carried them as trailing `# @cheat` comments that the
-- generator text-scraped; the compositor is now the single source of truth, so
-- the cheatsheet cannot drift from the binds that are actually registered.

local programs = require("components.programs")

local mainMod = "SUPER" -- Caps Lock remapped to Super via kb_options
local home    = os.getenv("HOME")
local dsp     = hl.dsp

hl.bind(mainMod .. " + RETURN",   dsp.exec_cmd(programs.terminal),    { desc = "Apps: Open terminal" })
hl.bind(mainMod .. " + SHIFT + R", dsp.exec_cmd("hyprctl reload"),    { desc = "System: Reload Hyprland" })
hl.bind(mainMod .. " + Q",        dsp.window.close(),                 { desc = "Window: Close active window" })
hl.bind(mainMod .. " + X",        dsp.exit(),                         { desc = "System: Exit Hyprland" })
hl.bind(mainMod .. " + E",        dsp.exec_cmd(programs.fileManager), { desc = "Apps: Open file manager (yazi TUI)" })
hl.bind(mainMod .. " + SHIFT + E", dsp.exec_cmd("thunar"),            { desc = "Apps: Open GUI file manager (Thunar)" })
hl.bind(mainMod .. " + C",        dsp.window.float({ action = "toggle" }), { desc = "Window: Toggle floating" })
hl.bind(mainMod .. " + P",        dsp.window.pseudo(),                { desc = "Window: Toggle pseudotile" })  -- dwindle
hl.bind(mainMod .. " + S",        dsp.layout("togglesplit"),          { desc = "Layout: Toggle split" })       -- dwindle
hl.bind(mainMod .. " + F",        dsp.window.fullscreen(),            { desc = "Window: Toggle fullscreen" })

-- Resize the window size using SUPER + R
hl.bind(mainMod .. " + R", dsp.submap("resize"), { desc = "Window: Resize mode (h/j/k/l)" })
hl.define_submap("resize", function()
    hl.bind("l",      dsp.window.resize({ x =  30, y =   0 }))
    hl.bind("h",      dsp.window.resize({ x = -30, y =   0 }))
    hl.bind("k",      dsp.window.resize({ x =   0, y = -30 }))
    hl.bind("j",      dsp.window.resize({ x =   0, y =  30 }))
    hl.bind("Return", dsp.submap("reset"))
end)

-- Move focus with mainMod + hjkl
hl.bind(mainMod .. " + H", dsp.focus({ direction = "left" }),  { desc = "Window: Focus left" })
hl.bind(mainMod .. " + L", dsp.focus({ direction = "right" }), { desc = "Window: Focus right" })
hl.bind(mainMod .. " + K", dsp.focus({ direction = "up" }),    { desc = "Window: Focus up" })
hl.bind(mainMod .. " + J", dsp.focus({ direction = "down" }),  { desc = "Window: Focus down" })

-- Switch workspaces with mainMod + [0-9]
-- Kept as two separate loops, not one interleaved loop: the cheatsheet renders
-- binds in registration order, and this preserves the "all switches, then all
-- moves" grouping the hyprlang config had.
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,
            dsp.focus({ workspace = i }),
            { desc = "Workspace: Switch to workspace " .. i })
end

-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + SHIFT + " .. key,
            dsp.window.move({ workspace = i }),
            { desc = "Workspace: Move window to workspace " .. i })
end

hl.bind(mainMod .. " + SHIFT + H", dsp.window.swap({ direction = "left" }),  { desc = "Window: Swap left" })
hl.bind(mainMod .. " + SHIFT + L", dsp.window.swap({ direction = "right" }), { desc = "Window: Swap right" })
hl.bind(mainMod .. " + SHIFT + K", dsp.window.swap({ direction = "up" }),    { desc = "Window: Swap up" })
hl.bind(mainMod .. " + SHIFT + J", dsp.window.swap({ direction = "down" }),  { desc = "Window: Swap down" })

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse_up",   dsp.focus({ workspace = "e+1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
local el = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, desc = "Media: Volume up" })
hl.bind("XF86AudioLowerVolume",  dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true, desc = "Media: Volume down" })
hl.bind("XF86AudioMute",         dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true, desc = "Media: Mute audio" })
hl.bind("XF86AudioMicMute",      dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true, desc = "Media: Mute microphone" })
hl.bind("XF86MonBrightnessUp",   dsp.exec_cmd("brightnessctl -n1 set 5%+"),                      { locked = true, repeating = true, desc = "System: Brightness up" })
hl.bind("XF86MonBrightnessDown", dsp.exec_cmd("brightnessctl -n1 set 5%-"),                      { locked = true, repeating = true, desc = "System: Brightness down" })

-- Requires playerctl
hl.bind("XF86AudioNext",  dsp.exec_cmd("playerctl next"),       { locked = true, desc = "Media: Next track" })
hl.bind("XF86AudioPause", dsp.exec_cmd("playerctl play-pause"), { locked = true, desc = "Media: Play/pause" })
hl.bind("XF86AudioPlay",  dsp.exec_cmd("playerctl play-pause"), { locked = true, desc = "Media: Play/pause" })
hl.bind("XF86AudioPrev",  dsp.exec_cmd("playerctl previous"),   { locked = true, desc = "Media: Previous track" })

-- Quickshell surfaces, driven through the global-shortcuts protocol
hl.bind(mainMod .. " + space",     dsp.global("quickshell:launcher_toggle"),           { desc = "Apps: App launcher" })
hl.bind(mainMod .. " + N",         dsp.global("quickshell:notifications_toggle"),      { desc = "System: Notification center" })
hl.bind(mainMod .. " + W",         dsp.global("quickshell:dashboard_toggle"),          { desc = "System: Widget dashboard" })
hl.bind(mainMod .. " + Y",         dsp.global("quickshell:lyrics_toggle"),             { desc = "Media: Lyrics strip" })
hl.bind(mainMod .. " + SHIFT + Y", dsp.global("quickshell:lyrics_karaoke_toggle"),     { desc = "Media: Full-screen karaoke lyrics" })
hl.bind(mainMod .. " + TAB",       dsp.global("quickshell:overview_toggle"),           { desc = "Window: Workspace overview" })

-- Alt-tab window switcher — hold Super+Alt, Tab cycles MRU windows, Shift+Tab
-- reverses, Delete/Q closes the highlighted one, release Super commits (Enter
-- is a fallback commit). The opening chord both advances the cycle and enters
-- the submap that owns every subsequent key while Super+Alt stay held.
hl.bind(mainMod .. " + ALT + Tab", dsp.global("quickshell:overview_altTabNext"),
        { desc = "Window: Alt-tab switcher (hold, Tab cycles, release to focus)" })
hl.bind(mainMod .. " + ALT + Tab", dsp.submap("altTab"))
hl.define_submap("altTab", function()
    hl.bind(mainMod .. " + ALT + Tab",         dsp.global("quickshell:overview_altTabNext"))
    hl.bind(mainMod .. " + ALT + SHIFT + Tab", dsp.global("quickshell:overview_altTabPrev"))
    hl.bind(mainMod .. " + ALT + Delete",      dsp.global("quickshell:overview_altTabClose"))
    hl.bind(mainMod .. " + ALT + Q",           dsp.global("quickshell:overview_altTabClose"))
    -- Commit/cancel. The primary commit is releasing Super, which is detected in
    -- QML (Overview.qml) — Hyprland cannot dispatch a bind on a modifier-KEY release
    -- (modifiers are consumed as modifier-state, never matched as a keysym/keycode —
    -- verified by instrumentation). Enter is kept as an explicit fallback commit;
    -- both the modifier-held and bare variants are bound so it works whether or not
    -- Super+Alt are still down.
    hl.bind(mainMod .. " + ALT + return", dsp.global("quickshell:overview_altTabCommit"))
    hl.bind(mainMod .. " + ALT + return", dsp.submap("reset"))
    hl.bind("return",                     dsp.global("quickshell:overview_altTabCommit"))
    hl.bind("return",                     dsp.submap("reset"))
    hl.bind(mainMod .. " + ALT + escape", dsp.global("quickshell:overview_altTabCancel"))
    hl.bind(mainMod .. " + ALT + escape", dsp.submap("reset"))
    hl.bind("escape",                     dsp.global("quickshell:overview_altTabCancel"))
    hl.bind("escape",                     dsp.submap("reset"))
end)

hl.bind(mainMod .. " + slash",     dsp.global("quickshell:cheatsheet_toggle"), { desc = "System: Keybinding cheatsheet" })
hl.bind(mainMod .. " + backspace", dsp.global("quickshell:settings_toggle"),   { desc = "System: Settings panel" })

-- Touchpad on/off — state lives in quickshell/touchpad-config.json, shared with
-- the Settings → Input switch. Persists across reboots and hyprctl reload.
hl.bind(mainMod .. " + SHIFT + T", dsp.exec_cmd(home .. "/.config/hypr/scripts/toggle-touchpad.sh"),
        { desc = "System: Toggle touchpad" })

-- Lock screen — Quickshell lockscreen; hyprlock kept as a fallback
hl.bind(mainMod .. " + escape", dsp.exec_cmd("qs -p " .. home .. "/.config/quickshell/lock-screen.qml -d -n"),
        { desc = "System: Lock screen" })
hl.bind(mainMod .. " + SHIFT + escape",
        dsp.exec_cmd([[bash -c 'p=$(fcitx5-remote); fcitx5-remote -c; hyprlock; [ "$p" = 2 ] && fcitx5-remote -o']]),
        { desc = "System: Lock screen (hyprlock fallback)" })

hl.bind(mainMod .. " + V", dsp.exec_cmd("cursor-clip"), { desc = "Apps: Clipboard history" })

-- Screenshot
hl.bind(mainMod .. " + SHIFT + S", dsp.exec_cmd("hyprshot -m region --freeze -o " .. home .. "/Pictures/Screenshot"), { desc = "Screenshot: Region" })
hl.bind("PRINT",                   dsp.exec_cmd("hyprshot -m output --freeze -o " .. home .. "/Pictures/Screenshot"), { desc = "Screenshot: Full screen" })
hl.bind(mainMod .. " + SHIFT + PRINT", dsp.exec_cmd("hyprshot -m window --freeze -o " .. home .. "/Pictures/Screenshot"), { desc = "Screenshot: Active window" })

-- Color picker — copies hex to clipboard
hl.bind(mainMod .. " + SHIFT + C",
        dsp.exec_cmd([[hyprpicker -a -f hex && notify-send "Color picker" "Copied $(wl-paste)"]]),
        { desc = "Apps: Color picker" })
