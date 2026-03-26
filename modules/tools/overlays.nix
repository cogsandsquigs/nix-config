{ ... }:
let
    overlays = [
        # (final: _prev: {
        #     unstable = import inputs.nixpkgs-unstable { inherit (final) config system; };
        # })
    ];
in
{
    flake.modules.darwin.overlays = {
        nixpkgs.overlays = overlays;
    };

    flake.modules.nixos.overlays = {
        nixpkgs.overlays = overlays;
    };

    # NOTE: Using `useGlobalPkgs` means that home-manager will use the global pkgs of the system, so
    # we don't need to configure any `nixpkgs` settings for it.
    #
    #flake.modules.homeManager.overlays = {
    #    nixpkgs.overlays = overlays;
    #};
}
