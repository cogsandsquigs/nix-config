let
    shared = { pkgs, ... }: {
        fonts.packages = with pkgs; [
            nerd-fonts.fira-code
            dejavu_fonts
            twitter-color-emoji
            atkinson-hyperlegible
            atkinson-hyperlegible-next
        ];
    };
in
{
    flake.modules.nixos.fonts = shared;
    flake.modules.darwin.fonts = shared;
}
