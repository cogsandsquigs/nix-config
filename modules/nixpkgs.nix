# nixpkgs settings and overlays.
#
# Applies to the system and, through home-manager's `useGlobalPkgs`, to the home configuration too. A
# standalone home-manager host has no system layer, so tools/default.nix instantiates its `pkgs` with
# the same config attribute -- step 4 of the migration moves that shared value into one file so the two
# cannot drift.
let
    nixpkgs = _: {
        nixpkgs = {
            config = {
                allowUnfree = true;
                qt.enable = true;
            };

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
