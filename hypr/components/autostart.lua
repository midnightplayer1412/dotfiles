-----------------
--- AUTOSTART ---
-----------------

-- hyprlang had two keywords; lua expresses the difference structurally:
--   exec-once  →  hl.on("hyprland.start", ...)   fires once, at login only
--   exec       →  a top-level hl.exec_cmd(...)   the config file is re-executed
--                                                on every reload, so these run
--                                                at login AND on every reload
local home = os.getenv("HOME")

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
hl.on("hyprland.start", function()
    hl.exec_cmd("fcitx5")
    -- Do NOT add --format bgr/rgb here. The 3-channel formats really are 3/4 the
    -- memory (measured: 6075Kb vs 8100Kb buffers), but this compositor rejects them:
    -- the daemon gets "WAYLAND PROTOCOL ERROR: Format invalid" from wlroots, then
    -- panics with BrokenPipe at daemon/src/main.rs:712 and core-dumps on startup.
    -- The result is a black desktop with no wallpaper daemon at all.
    -- Verified 2026-07-21: argb and abgr (4-channel) work; bgr and rgb both die.
    -- awww-daemon --help hints at this — argb is the default "because it is most
    -- widely supported".
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("cursor-clip --daemon")
end)

-- Regenerate the Super+/ cheatsheet keymap on every reload, so it can never
-- drift from the actual binds. MUST stay above the quickshell relaunch below:
-- KeymapData loads the JSON once at startup with no file watching, so a shell
-- that starts first would show the previous keymap until the next reload.
--
-- Under the lua config this reads the live compositor (`hyprctl binds -j`)
-- rather than text-scraping the config, so it picks up the `desc` field that
-- components/binds.lua attaches to each bind.
hl.exec_cmd(home .. "/.config/hypr/scripts/gen-keymap.sh")

-- Kill BOTH possible process names (qs and quickshell are the same binary) before
-- relaunching, so a config reload always converges to exactly one instance.
hl.exec_cmd("pkill -x quickshell; pkill -x qs; quickshell")

-- Runs at login AND on every config reload. A reload re-reads touchpad.lua
-- (which always declares `enabled = true` as the boot default), so without this
-- line Super+Shift+R would silently re-enable a touchpad the user had turned off.
hl.exec_cmd(home .. "/.config/hypr/scripts/apply-touchpad.sh")
