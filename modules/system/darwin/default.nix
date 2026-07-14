# Everything a Mac (nix-darwin) machine gets. Read top-down to see exactly what is included.
{ inputs, ... }: {
    imports = [
        ../common
        inputs.home-manager.darwinModules.home-manager
        ../../home-manager.nix

        ./nix.nix
        ./system-defaults.nix
        ./apps-fix.nix
        ./packages.nix
        ./games.nix
        ./desktop-apps.nix
        ./secrets.nix
        ./users.nix
        ./fuse.nix
    ];
}
