{pkgs, ...}: {
    # Fonts
    fonts = {
        packages = with pkgs; [
            nerd-fonts.fira-code
            atkinson-hyperlegible # Old version
            atkinson-hyperlegible-next # New version (preferred!)
        ];
    };
}
