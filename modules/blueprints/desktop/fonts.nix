{ ... }:
let
    fonts = pkgs: {
        fonts = {
            packages = with pkgs; [
                nerd-fonts.fira-code
                atkinson-hyperlegible # Old version
                atkinson-hyperlegible-next # New version (preferred!)
            ];
        };
    };
in

{
    flake.modules.nixos.desktop = { pkgs, ... }: fonts pkgs;
    flake.modules.darwin.desktop = { pkgs, ... }: fonts pkgs;
}
