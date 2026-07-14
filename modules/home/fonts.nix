# Fonts installed system-wide.
{
    pkgs,
    lib,
    config,
    tools,
    ...
}:
{
    options.my.user.fonts.enable = tools.opt.mkEnabled "Fonts (Fira Code, Atkinson Hyperlegible)";

    config = lib.mkIf config.my.user.fonts.enable {
        home-manager = {

            fonts = {
                fontconfig.enable = true;
            };
        };

        home = {
            packages = with pkgs; [
                nerd-fonts.fira-code
                atkinson-hyperlegible # Old version
                atkinson-hyperlegible-next # New version (preferred!)
            ];
        };
    };
}
