# nixpkgs settings + overlays. Applies to the system and, via home-manager's `useGlobalPkgs`,
# to the home configuration too.
{ ... }:
let
    overlays = [
        # (final: _prev: {
        #     unstable = import inputs.nixpkgs-unstable { inherit (final) config system; };
        # })
    ];
in
{
    nixpkgs = {
        config = {
            allowUnfree = true;
            qt.enable = true;
        };

        overlays = overlays;
    };
}
