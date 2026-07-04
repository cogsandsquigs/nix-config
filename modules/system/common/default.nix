# System configuration valid on BOTH darwin and nixos. Imported by each class's default.nix.
{ ... }: {
    imports = [
        ./nixpkgs.nix
        ./shells.nix
    ];
}
