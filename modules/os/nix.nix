# Nix itself.
#
# On darwin, Determinate Nix owns the configuration and nix-darwin's own `nix.*` is switched off. On
# NixOS, `nix.*` does the work. The caches, keys and trusted users are the same either way, so they are
# stated once here rather than copy-pasted into two files that then drift.
let
    # Substituters let us skip building by downloading prebuilt outputs.
    substituters = [
        "https://cache.nixos.org"
        "https://nix-darwin.cachix.org"
        "https://nix-community.cachix.org"
        "https://install.determinate.systems"
    ];

    # Public keys for the substituters above. (cache.nixos.org's key is included by default.)
    trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-darwin.cachix.org-1:LxMyKzQk7Uqkc1Pfq5uhm9GSn07xkERpy+7cpwc006A="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM"
    ];

    trusted-users = [
        "root"
        "@wheel" # Users in `wheel` group
        "@admin" # Users in `admin` group (mainly MacOS)
    ];

    experimental-features = [
        "nix-command"
        "flakes"
    ];
in
{
    nixos = { inputs, ... }: {
        nix = {
            enable = true;
            registry.nixpkgs.flake = inputs.nixpkgs;

            settings = {
                inherit
                    substituters
                    trusted-public-keys
                    trusted-users
                    experimental-features
                    ;
                builders-use-substitutes = true;
            };

            # Collect garbage. See:
            # https://wiki.nixos.org/wiki/Storage_optimization#Garbage_collection
            gc = {
                automatic = true;
                options = "--delete-older-than 30d";
                dates = "weekly";
            };

            # Optimise the store on a schedule. See:
            # https://wiki.nixos.org/wiki/Storage_optimization#Optimising_the_store
            optimise = {
                automatic = true;
                dates = "weekly";
            };

            extraOptions = ''
                warn-dirty = false
                keep-outputs = true
            '';
        };
    };

    darwin =
        {
            inputs,
            lib,
            pkgs,
            ...
        }:
        {
            imports = [ inputs.determinate.darwinModules.default ];

            nix.enable = false; # Let Determinate Nix handle the Nix configuration.

            determinateNix = {
                enable = true;

                customSettings = {
                    inherit
                        substituters
                        trusted-public-keys
                        trusted-users
                        experimental-features
                        ;
                    builders-use-substitutes = true;

                    # Enables parallel evaluation (remove this setting or set the value to 1 to disable)
                    eval-cores = 0;

                    # Disable global registry
                    flake-registry = "";

                    # Allow us to use x86_64-darwin macos binaries on aarch64-darwin systems
                    extra-platforms = lib.mkIf (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") [
                        "x86_64-darwin"
                        "aarch64-darwin"
                    ];

                    lazy-trees = true;
                    warn-dirty = false;

                    extra-experimental-features = [
                        "build-time-fetch-tree" # Enables build-time flake inputs
                        "parallel-eval" # Enables parallel evaluation
                    ];
                };
            };
        };
}
