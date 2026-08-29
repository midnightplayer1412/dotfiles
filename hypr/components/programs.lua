-- Programs referenced from several config files.
--
-- hyprlang had one global `$terminal` namespace; lua locals do not cross file
-- boundaries, so the shared names live here and each consumer requires them.
return {
    terminal    = "kitty",
    fileManager = "kitty yazi",
    menu        = "hyprlauncher",
}
