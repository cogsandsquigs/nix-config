{
    description = ''
        My NixOS / nix-darwin / home-manager configuration for my daily-driver devices
        (personal MacBook + desktop, and a standalone home-manager work desktop).
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
        { ... }@inputs:
        let
            tools = import ./tools { inherit inputs; };

            # Each host's identity is the single source of truth in hosts/<name>/id.nix (see the
            # README `id.nix` convention). We read it here purely to form the output attribute
            # names; the builders re-import it and hand it to the modules as `hostId`.
            glorpbook = ./hosts/glorpbook;
            homeDesktop = ./hosts/home-desktop;
            workDesktop = ./hosts/work-desktop;

            idOf = host: import (host + "/id.nix");
            glorpbookId = idOf glorpbook;
            homeDesktopId = idOf homeDesktop;
            workId = idOf workDesktop;
        in
        {
            inherit tools;

            # Personal MacBook — "glorpbook" (nix-darwin).
            darwinConfigurations.${glorpbookId.hostName} = tools.mkDarwin glorpbook;

            # Personal desktop tower (NixOS).
            nixosConfigurations.${homeDesktopId.hostName} = tools.mkNixos homeDesktop;

            # Work desktop (standalone home-manager on Ubuntu 24, Nix installed per-user).
            # Apply with: home-manager switch --flake ~/.config/nix#<userName>@<hostName>
            homeConfigurations."${workId.primaryUser}@${workId.hostName}" = tools.mkHome {
                host = workDesktop;
            };

            # `nix fmt` → treefmt, driven by ./treefmt.toml (4-space, 100 cols — the repo's real
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
