{
    description = ''
        My NixOS / nix-darwin / home-manager configuration for my daily-driver devices
        (personal MacBook + desktop, and a standalone home-manager work desktop).
    '';

    inputs = {
        # Main packages repo
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # Unstable
        # nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05"; # Stable

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

        # Recursive module discovery, so `modules/` needs no hand-written import lists. Deliberately
        # the only framework-ish dependency here: its own flake.nix is `{ outputs = _: import ./.; }`,
        # so it has no inputs of its own and no nixpkgs dependency (pure builtins). flake.lock grows
        # by exactly one node and there is nothing to `follows`.
        import-tree.url = "github:vic/import-tree";

        ## Secrets and such ##

        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        ## Overlays ##

        # (Balena) Etcher. No nixpkgs package. Applied in modules/_overlays.nix.
        balena-etcher = {
            url = "github:sidharthify/balenaEtcher-flake";
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
        { self, ... }@inputs:
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

            # The feature registry, as the standard per-class module outputs. `nix flake show` then
            # lists every feature and its class -- the index the deleted default.nix import lists used
            # to approximate, except this one cannot be out of date.
            nixosModules = tools.registry.nixos;
            darwinModules = tools.registry.darwin;
            homeModules = tools.registry.homeManager;

            # `nix build .#<host>-vm` -> a bootable QEMU VM of that NixOS host. Derived from the
            # fleet like everything else, so this still names no machine. A platform with no NixOS
            # host of its own simply gets an empty set. `nix flake check` evaluates these and skips
            # building them, so the gates stay cheap.
            packages = tools.forAllSystems (pkgs: tools.vmPackages pkgs.stdenv.hostPlatform.system);

            # `nix flake check` -> the gates in ./tools/checks.nix. Runnable from any machine in the
            # fleet, including the checks that cover the machines it cannot build.
            checks = tools.forAllSystems (import ./tools/checks.nix { inherit self tools; });

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
