{pkgs, ...}: {
    # Fonts
    fonts = {
        packages = with pkgs; [
            nerd-fonts.fira-code
            atkinson-hyperlegible-next
        ];
    };
}
