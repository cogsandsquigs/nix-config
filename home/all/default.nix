{ pkgs, lib, ... }:
{
    imports =
        let
            inherit (lib.fileset)
                toList
                difference
                fileFilter
                unions
                ;
        in
        # From Set into List
        toList (
            # Remove `./default.nix` and `./overlays.nix` to avoid recursive import
            difference
                (
                    # Get all `.nix` files
                    fileFilter (file: file.hasExt "nix") ./.
                )
                (unions [
                    ./default.nix
                    (lib.fileset.maybeMissing ./overlays.nix)
                ])
        );

    home.stateVersion = "25.05"; # Home Manager version

    nixpkgs = {
        config = {
            allowUnfree = true;
            qt.enable = true;
        };

        overlays = [ ]; # (import ./overlays.nix);
    };

    home.packages = with pkgs; [ home-manager ];

}
