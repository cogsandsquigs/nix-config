{ inputs, lib, ... }:
let
    # Substituters allow us to skip building nixos configuration by downloading prebuilt ones.
    substituters = [
        "https://cache.nixos.org"
        "https://nix-darwin.cachix.org"
        "https://nix-community.cachix.org"
        "https://install.determinate.systems"
    ];

    # Public keys for the substituters above.
    # NOTE: The public key for `https://cache.nixos.org` is included by default. No need
    # to include it here!
    trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-darwin.cachix.org-1:LxMyKzQk7Uqkc1Pfq5uhm9GSn07xkERpy+7cpwc006A="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM"
    ];

    # Trusted users
    trusted-users = [
        "root"
        "@wheel" # Users in `wheel` group
        "@admin" # Users in `admin` group (mainly MacOS)
    ];
in
{
    flake.modules.darwin.base = {
        nixpkgs = {
            config = {
                allowUnfree = true;
                qt.enable = true;
            };
        };

        determinateNix = {
            enable = true;

            customSettings = {
                # Enables parallel evaluation (remove this setting or set the value to 1 to disable)
                eval-cores = 0;

                # Disable global registry
                flake-registry = "";

                lazy-trees = true;
                warn-dirty = false;

                experimental-features = [
                    "nix-command"
                    "flakes"
                ];

                extra-experimental-features = [
                    "build-time-fetch-tree" # Enables build-time flake inputs
                    "parallel-eval" # Enables parallel evaluation
                ];

                substituters = substituters;
                trusted-public-keys = trusted-public-keys;
                trusted-users = trusted-users;
                builders-use-substitutes = true;
            };
        };

        # nix = {
        #     enable = true;
        #     registry.nixpkgs.flake = inputs.nixpkgs;
        #     settings = {
        #         # enable flakes globally, enable `nix` command
        #         experimental-features = [
        #             "nix-command"
        #             "flakes"
        #         ];

        #         substituters = substituters;
        #         trusted-public-keys = trusted-public-keys;
        #         trusted-users = trusted-users;
        #         builders-use-substitutes = true;

        #     };

        #     # Collect garbage.
        #     # See: https://wiki.nixos.org/wiki/Storage_optimization#Garbage_collection
        #     gc = {
        #         automatic = true;
        #         options = "--delete-older-than 30d";

        #         # See: https://wiki.nixos.org/wiki/Storage_optimization#Automation

        #         # See: https://wiki.nixos.org/wiki/Storage_optimization#Automation
        #         # MacOS: The calendar interval at which the optimiser will run.
        #         # See the serviceConfig.StartCalendarInterval option of
        #         # the launchd (nix-darwin) module for more info.
        #         interval = {
        #             Weekday = 0;
        #             Hour = 0;
        #             Minute = 0;
        #         };
        #     };

        #     # See: https://wiki.nixos.org/wiki/Storage_optimization#Optimising_the_store and
        #     # see: https://www.reddit.com/r/NixOS/comments/1cunvdw/friendly_reminder_optimizestore_is_not_on_by/
        #     # Optimization settings for the nix store.
        #     # Will optimize the nix-store on a schedule.
        #     optimise = {
        #         automatic = true;

        #         # See: https://wiki.nixos.org/wiki/Storage_optimization#Automation
        #         # MacOS: The calendar interval at which the optimiser will run.
        #         # See the serviceConfig.StartCalendarInterval option of
        #         # the launchd (nix-darwin) module for more info.
        #         interval = {
        #             Weekday = 0;
        #             Hour = 0;
        #             Minute = 0;
        #         };

        #     };

        #     extraOptions = ''
        #         warn-dirty = false
        #         keep-outputs = true
        #     '';
        # };

    };

    flake.modules.nixos.base = {
        nixpkgs = {
            config = {
                allowUnfree = true;
                qt.enable = true;
            };
        };

        nix = {
            enable = true;
            registry.nixpkgs.flake = inputs.nixpkgs;
            settings = {
                # enable flakes globally, enable `nix` command
                experimental-features = [
                    "nix-command"
                    "flakes"
                ];

                substituters = substituters;
                trusted-public-keys = trusted-public-keys;
                trusted-users = trusted-users;
                builders-use-substitutes = true;

                # Collect garbage.
                # See: https://wiki.nixos.org/wiki/Storage_optimization#Garbage_collection

                gc = {
                    automatic = true;
                    options = "--delete-older-than 30d";

                    # See: https://wiki.nixos.org/wiki/Storage_optimization#Automation
                    # Linux: When to run the garbage collector.
                    dates = "weekly";
                };

                # See: https://wiki.nixos.org/wiki/Storage_optimization#Optimising_the_store and
                # see: https://www.reddit.com/r/NixOS/comments/1cunvdw/friendly_reminder_optimizestore_is_not_on_by/
                # Optimization settings for the nix store.
                # Will optimize the nix-store on a schedule.
                optimise = {
                    automatic = true;

                    # Linux: When to run the store optimizer.
                    dates = "weekly";
                };
            };

            extraOptions = ''
                warn-dirty = false
                keep-outputs = true
            '';
        };

    };
}
