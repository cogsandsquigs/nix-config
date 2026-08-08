# nixpkgs settings. These apply to the system and, through `useGlobalPkgs`, to home-manager too.
#
# The values live in ../_nixpkgs-config.nix and ../_overlays.nix. tools/default.nix reads the same
# two files from outside the module system, to build `pkgs` for a standalone home-manager host.
let
    nixpkgs = { inputs, ... }: {
        nixpkgs = {
            config = import ../_nixpkgs-config.nix;
            overlays = import ../_overlays.nix inputs;
        };
    };
in
{
    nixos = nixpkgs;
    darwin = nixpkgs;
}
