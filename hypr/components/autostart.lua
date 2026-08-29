-----------------
--- AUTOSTART ---
-----------------

-- hyprlang's two keywords map onto lua EVENTS, not onto file position:
--
--   exec-once  →  run from hl.on("hyprland.start", ...)          login only
--   exec       →  run from BOTH "hyprland.start" and             login AND
--                 "config.reloaded"                              every reload
--
-- A top-level hl.exec_cmd(...) is NOT the equivalent of `exec`. It fires while
-- the config file is still executing — long before the compositor serves
-- Wayland clients or answers hyprctl. Measured at the 0.56.2 migration: the
-- three commands below ran at hyprland.log lines 16-20, before init finished.
-- Quickshell started there exits immediately with no display to connect to,
-- and both hyprctl-driven scripts get no reply. "hyprland.start" is the event
-- Hyprland's own example config uses to launch Wayland clients, so it is late
-- enough; "config.reloaded" fires once per reload, after the file re-executes.
--
-- Deliberately NOT de-duplicated with a "already ran this load" flag. If both
-- events ever fire for a single login, the cost is one redundant pass: the
-- quickshell line kills before starting, and both scripts are idempotent. A
-- flag would instead let a too-early first call block the good one, which is
-- exactly the failure this file is structured to avoid.

local home = os.getenv("HOME")

-- `exec` equivalent — must survive a reload, not just a login.
local function applyRuntimeState()
    -- Regenerate the Super+/ cheatsheet keymap, so it can never drift from the
    -- actual binds. MUST stay above the quickshell relaunch below: KeymapData
    -- loads the JSON once at startup with no file watching, so a shell that
    -- starts first would show the previous keymap until the next reload.
    --
    -- Reads the live compositor (`hyprctl binds -j`) rather than the config
    -- text, picking up the `desc` on each bind in components/binds.lua.
    hl.exec_cmd(home .. "/.config/hypr/scripts/gen-keymap.sh")

    -- Kill BOTH possible process names (qs and quickshell are the same binary)
    -- before relaunching, so a config reload always converges to exactly one
    -- instance.
    hl.exec_cmd("pkill -x quickshell; pkill -x qs; quickshell")

    -- Runs at login AND on every reload. A reload re-reads touchpad.lua (which
    -- always declares `enabled = true` as the boot default), so without this
    -- a Super+Shift+R would silently re-enable a touchpad the user turned off.
    hl.exec_cmd(home .. "/.config/hypr/scripts/apply-touchpad.sh")
end

hl.on("hyprland.start", function()
    -- `exec-once` equivalent — one-shot daemons, login only.
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

    applyRuntimeState()
end)

hl.on("config.reloaded", applyRuntimeState)
