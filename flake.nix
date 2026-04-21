{
    description = ''
        My personal NixOS/Nix-Darwin configuration for my daily driver devices.
    '';

    inputs = {
        # Main packages repo
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Unstable

        # MacOS config
        nix-darwin = {
            url = "github:nix-darwin/nix-darwin/master"; # Unstable
            inputs.nixpkgs.follows = "nixpkgs";
        };

        ## Tools ##

        # Home Manager
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # Determinate Nix is Determinate Systems' validated and secure downstream distribution of
        # NixOS/nix.
        #  - https://determinate.systems/nix/
        #  - https://docs.determinate.systems/guides/nix-darwin/
        # Determinate 3.* module
        determinate = {
            url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        ## Utilities ##

        # These two force structure, reducing refactoring friction
        flake-parts.url = "github:hercules-ci/flake-parts"; # Extensible flake API
        import-tree.url = "github:vic/import-tree"; # Import modules recursively from file-tree

        ## Secrets and such ##

        agenix = {
            url = "github:ryantm/agenix";
            inputs.home-manager.follows = "home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        secrets = {
            flake = false;
            url = "path:./secrets";
        };
    };

    outputs =
        inputs@{ flake-parts, import-tree, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } (import-tree ./modules);
}
