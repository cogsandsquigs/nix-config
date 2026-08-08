# nixpkgs settings.
#
# Applies to the system and, through home-manager's `useGlobalPkgs`, to the home configuration too. The
# `config` values live in ../_nixpkgs-config.nix and the `overlays` list in ../_overlays.nix, because
# tools/default.nix needs the same ones from outside the module system, to instantiate `pkgs` for a
# standalone home-manager host.
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
