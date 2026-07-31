# nixpkgs settings and overlays.
#
# Applies to the system and, through home-manager's `useGlobalPkgs`, to the home configuration too. The
# `config` values live in ../_nixpkgs-config.nix because tools/default.nix needs the same ones from
# outside the module system, to instantiate `pkgs` for a standalone home-manager host.
let
    nixpkgs = _: {
        nixpkgs = {
            config = import ../_nixpkgs-config.nix;

            overlays = [
                # (final: _prev: {
                #     unstable = import inputs.nixpkgs-unstable { inherit (final) config system; };
                # })
            ];
        };
    };
in
{
    nixos = nixpkgs;
    darwin = nixpkgs;
}
