{
    description = ''
        My personal NixOS/Nix-Darwin configuration for my daily driver devices.
    '';

    inputs = {
        # Main packages repo
        # nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Unstable
        nixpkgs.url = "github:NixOS/nixpkgs/release-26.05"; # Stable

        # MacOS config
        nix-darwin = {
            # url = "github:nix-darwin/nix-darwin/master"; # Unstable
            url = "github:nix-darwin/nix-darwin/nix-darwin-26.05"; # Stable
            inputs.nixpkgs.follows = "nixpkgs";
        };

        ## Tools ##

        # Home Manager
        home-manager = {
            # url = "github:nix-community/home-manager/master"; # Unstable
            url = "github:nix-community/home-manager/release-26.05"; # Stable
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

    # Plain-flake composition: every file under ./modules is an ordinary NixOS / nix-darwin /
    # home-manager module, and the directory tree *is* the import graph. `./lib` exposes the
    # `mkDarwin` / `mkNixos` builders that wire a host together.
    outputs =
        { nixpkgs, ... }@inputs:
        let
            lib = import ./lib { inherit inputs; };
        in
        {
            inherit lib;

            darwinConfigurations."Ians-GlorpBook-Pro" = lib.mkDarwin ./hosts/macbook;

            nixosConfigurations.desktop = lib.mkNixos ./hosts/desktop;

            formatter = lib.forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
        };
}
