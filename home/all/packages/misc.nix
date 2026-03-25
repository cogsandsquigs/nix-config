{ pkgs, ... }:
{
    home.packages = with pkgs; [
        # discord # NOTE: See system/darwin/homebrew.nix for why we use homebrew ver
        # spotify
        # postman
        zoom-us
        # kicad-testing
    ];
}
