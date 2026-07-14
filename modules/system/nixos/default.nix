# Everything a NixOS machine gets. Currently only the `home-desktop` host uses this; fill in
# more as that machine takes shape.
{ inputs, ... }: {
    imports = [
        ../common
        inputs.home-manager.nixosModules.home-manager
        ../../home-manager.nix

        ./nix.nix
        ./security.nix
        ./games.nix
        ./secrets.nix
        ./users.nix
    ];
}
