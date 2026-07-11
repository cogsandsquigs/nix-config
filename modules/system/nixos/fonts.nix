# Fonts installed system-wide.
{
    pkgs,
    lib,
    config,
    tools,
    ...
}:
{
    options.my.sys.fonts.enable =
        tools.mkEnabled "system-wide fonts (Fira Code, Atkinson Hyperlegible)";

    config = lib.mkIf config.my.sys.fonts.enable {
        fonts = {
            packages = with pkgs; [
                nerd-fonts.fira-code
                atkinson-hyperlegible # Old version
                atkinson-hyperlegible-next # New version (preferred!)
            ];
        };
    };
}
