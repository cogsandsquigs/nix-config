# Fonts installed system-wide.
{
    home =
        {
            pkgs,
            lib,
            config,
            tools,
            ...
        }:
        {
            options.my.user.fonts.enable =
                tools.opt.mkEnabled "Fonts (Fira Code, DejaVu, Atkinson Hyperlegible)";

            config = lib.mkIf config.my.user.fonts.enable {
                fonts.fontconfig.enable = true;

                home.packages = with pkgs; [
                    nerd-fonts.fira-code
                    dejavu_fonts
                    noto-fonts-color-emoji
                    atkinson-hyperlegible # Old version
                    atkinson-hyperlegible-next # New version (preferred!)
                ];
            };
        };
}
