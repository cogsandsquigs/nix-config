{
    description = ''
        My personal NixOS/Nix-Darwin configuration for my daily driver devices.
    '';

    inputs = {
        # Main packages repo
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Unstable

        # These two force structure, reducing refactoring friction
        flake-parts.url = "github:hercules-ci/flake-parts"; # Extensible flake API
        import-tree.url = "github:vic/import-tree"; # Import modules recursively from file-tree

        # MacOS config
        nix-darwin = {
            url = "github:nix-darwin/nix-darwin/master"; # Unstable
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # Home Manager
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs =
        inputs@{ flake-parts, import-tree, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } (import-tree ./modules);
}
