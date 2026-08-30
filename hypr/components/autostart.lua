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
-- Measured at login: "config.reloaded" DOES fire on the initial config load,
-- during parse, before the backend exists — so it lands in the same too-early
-- window. "hyprland.start" then fires after init and does the real work.
--
-- So the two handlers are guarded differently, and deliberately NOT by an
-- "already ran this load" flag. A flag keyed on having run would let the early
-- config.reloaded claim it and suppress the good hyprland.start pass — exactly
-- the failure this file exists to avoid. The guard is on compositor READINESS
-- instead, and only config.reloaded carries it: hyprland.start is known to be
-- late enough (it is the event Hyprland's own example uses to launch Wayland
-- clients), so it runs unconditionally and can never be gated off by a probe
-- returning a false negative.

local home = os.getenv("HOME")

-- Empty until the backend is up, so this separates a reload (compositor live,
-- act now) from the initial parse (nothing serving yet, wait for the event).
local function compositorReady()
    local ok, monitors = pcall(hl.get_monitors)
    return ok and monitors ~= nil and #monitors > 0
end

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

    -- polkit authentication agent. Without one, polkitd is running but nothing
    -- can ever draw a password prompt: pkexec and every GUI privilege escalation
    -- fail outright rather than asking. polkit-kde-agent is the only agent
    -- installed here (hyprpolkitagent is in extra, but was never pulled in), and
    -- its binary lives in /usr/lib and is NOT on PATH, hence the absolute path.
    --
    -- The package also ships plasma-polkit-agent.service, but it is unusable in
    -- this session: it is `static` (no [Install] section, so it cannot be
    -- enabled) and is ordered After=plasma-core.target, a target that never
    -- exists outside Plasma. Launching the binary directly is the route that
    -- works under Hyprland.
    --
    -- Belongs in exec-once, not applyRuntimeState: the agent claims the D-Bus
    -- name org.kde.polkit-kde-authentication-agent-1, so a second copy spawned by
    -- a config reload would only fail to register and exit.
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

    applyRuntimeState()
end)

-- Reloads only. At login this fires during parse, before anything is serving;
-- the readiness guard drops that pass so it does not spawn three processes that
-- immediately die. The hyprland.start handler above covers the login case.
hl.on("config.reloaded", function()
    if compositorReady() then applyRuntimeState() end
end)
