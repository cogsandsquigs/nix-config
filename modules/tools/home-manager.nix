# NOTE: This is imported only in `modules/users/*` configurations, as home-manager is a per-user
# thing.
{ inputs, ... }:
let
    home-manager-config = { ... }: {
        home-manager = {
            verbose = true;
            useUserPackages = true;
            useGlobalPkgs = true;
            overwriteBackup = true;
        };
    };
in
{
    flake.modules.nixos.tools.home-manager = {
        imports = [
            inputs.home-manager.nixosModules.home-manager
            home-manager-config
        ];
    };

    flake.modules.darwin.tools.home-manager = {
        imports = [
            inputs.home-manager.darwinModules.home-manager
            home-manager-config
        ];
    };
}
