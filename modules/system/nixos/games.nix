# Steam (native on NixOS).
{
    lib,
    config,
    tools,
    ...
}:
{
    options.my.sys.games.enable = tools.opt.mkDisabled "Steam (native on NixOS)";

    config = lib.mkIf config.my.sys.games.enable {
        programs.steam = {
            enable = true;
        };
    };
}
