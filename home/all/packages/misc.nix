{ pkgs, ... }:
{
    home.packages = with pkgs; [
        # discord # NOTE: See system/darwin/homebrew.nix for why we use homebrew ver
        obsidian
        # spotify
        # postman
        zoom-us
        # inetutils
        # kicad-testing
    ];
}
