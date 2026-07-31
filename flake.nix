{
    description = ''
        My NixOS / nix-darwin / home-manager configuration for my daily-driver devices
        (personal MacBook + desktop, and a standalone home-manager work desktop).
    '';

    inputs = {
        # Main packages repo
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Unstable
        # nixpkgs.url = "github:NixOS/nixpkgs/release-26.05"; # Stable

        # MacOS config
        nix-darwin = {
            url = "github:nix-darwin/nix-darwin/master"; # Unstable
            # url = "github:nix-darwin/nix-darwin/nix-darwin-26.05"; # Stable
            inputs.nixpkgs.follows = "nixpkgs";
        };

        ## Tools ##

        # Home Manager
        home-manager = {
            url = "github:nix-community/home-manager/master"; # Unstable
            # url = "github:nix-community/home-manager/release-26.05"; # Stable
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

        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    # Plain-flake composition: every file under ./modules is an ordinary NixOS / nix-darwin /
    # home-manager module, and the directory tree *is* the import graph. `./tools` exposes the typed
    # fleet and the builders that wire a host together.
    #
    # No host is named here. Each machine declares its class in hosts/<name>/id.nix, and ./tools maps
    # the fleet onto the right builder, so adding a host touches only its own directory.
    outputs =
        { ... }@inputs:
        let
            tools = import ./tools {
                inherit inputs;
                root = ./.;
            };
        in
        {
            inherit (tools)
                fleet
                nixosConfigurations
                darwinConfigurations
                homeConfigurations
                ;

            # `nix fmt` -> treefmt, driven by ./treefmt.toml (4-space, 100 cols -- the repo's real
            # style). Wrapped with the formatters treefmt invokes (nixfmt/shfmt/prettier) on PATH
            # so `nix fmt` is self-contained and matches editor + `treefmt` output.
            formatter = tools.forAllSystems (
                pkgs:
                pkgs.writeShellApplication {
                    name = "treefmt";
                    runtimeInputs = [
                        pkgs.treefmt
                        pkgs.nixfmt
                        pkgs.shfmt
                        pkgs.prettier
                    ];
                    text = ''exec treefmt "$@"'';
                }
            );
        };
}
