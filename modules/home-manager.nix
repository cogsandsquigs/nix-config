# Home Manager as a NixOS / nix-darwin submodule. Per-user config lives with the host; shared HM
# basics go in `flake.modules.homeManager.base` (applied to every user via `sharedModules`).
{ inputs, self, ... }:
let
    shared = {
        home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            sharedModules = [ self.modules.homeManager.base ];
        };
    };
in
{
    flake.modules = {
        nixos.home-manager.imports = [
            inputs.home-manager.nixosModules.home-manager
            shared
        ];

        darwin.home-manager.imports = [
            inputs.home-manager.darwinModules.home-manager
            shared
        ];

        homeManager.base = { };
    };
}
