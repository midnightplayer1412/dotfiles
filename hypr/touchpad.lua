-- Per-device touchpad config.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
hl.device({
    name = "asup1205:00-093a:2008-touchpad",

    enabled = true,

    -- Recommended touchpad options
    natural_scroll         = true,
    clickfinger_behavior   = true,
    -- Physical press only — a light tap on the surface must not click.
    -- Boot default, same deal as `enabled` above: apply-touchpad.sh re-applies
    -- the real state from touchpad-config.json on login and on every reload,
    -- so flipping this in Settings → Input sticks.
    -- (hyprlang spelled this `tap-to-click`; lua uses `tap_to_click`.)
    tap_to_click           = false,
    scroll_factor          = 0.8,
    sensitivity            = 0.6,
    middle_button_emulation = true,
})
