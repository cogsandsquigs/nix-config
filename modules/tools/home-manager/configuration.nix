{ inputs, ... }:
let
    home-manager-config =
        { ... }:
        {
            home-manager = {
                verbose = true;
                useUserPackages = true;
                useGlobalPkgs = true;
                overwriteBackup = true;
            };
        };
in
{
    flake.modules.nixos.home-manager = {
        imports = [
            inputs.home-manager.nixosModules.home-manager
            home-manager-config
        ];
    };

    flake.modules.darwin.home-manager = {
        imports = [
            inputs.home-manager.darwinModules.home-manager
            home-manager-config
        ];
    };
}
