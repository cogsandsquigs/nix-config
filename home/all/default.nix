{ pkgs, lib, ... }:
{
    imports =
        let
            inherit (lib.fileset) toList difference fileFilter;
        in
        toList (difference (fileFilter (file: file.hasExt "nix") ./.) ./default.nix);

    home.stateVersion = "25.05"; # Home Manager version
    nixpkgs.config.allowUnfree = true;

    home.packages = with pkgs; [ home-manager ];

}
