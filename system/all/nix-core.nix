# Taken from https://github.com/ryan4yin/nix-darwin-kickstarter/blob/main/minimal/modules/nix-core.nix
{
    inputs,
    pkgs,
    lib,
    username,
    ...
}:
let
    inherit (pkgs) stdenv;
    mkIf = lib.mkIf;
in
{
    nix = {
        # Auto upgrade nix package and the daemon service.
        enable = true;

        registry.nixpkgs.flake = inputs.nixpkgs;

        settings = {
            # enable flakes globally, enable `nix` command
            experimental-features = [
                "nix-command"
                "flakes"
            ];

            # Substituters allow us to skip building nixos configuration by downloading prebuilt ones.
            substituters = [
                "https://cache.nixos.org"
                "https://nix-darwin.cachix.org"
                "https://nix-community.cachix.org"
            ];

            # Public keys for the substituters above.
            # NOTE: The public key for `https://cache.nixos.org` is included by default. No need
            # to include it here!
            trusted-public-keys = [
                "nix-darwin.cachix.org-1:LxMyKzQk7Uqkc1Pfq5uhm9GSn07xkERpy+7cpwc006A="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            ];

            trusted-users = [ username ];

            builders-use-substitutes = true;
            auto-optimise-store = mkIf stdenv.isLinux true;
        };

        # Collect garbage.
        # See: https://wiki.nixos.org/wiki/Storage_optimization#Garbage_collection

        gc = {
            automatic = true;
            options = "--delete-older-than 30d";

            # See: https://wiki.nixos.org/wiki/Storage_optimization#Automation

            # See: https://wiki.nixos.org/wiki/Storage_optimization#Automation
            # MacOS: The calendar interval at which the optimiser will run.
            # See the serviceConfig.StartCalendarInterval option of
            # the launchd (nix-darwin) module for more info.
            interval = mkIf stdenv.isDarwin {
                Weekday = 0;
                Hour = 0;
                Minute = 0;
            };

            # Linux: When to run the garbage collector.
            dates = mkIf stdenv.isLinux "weekly";
        };

        # See: https://wiki.nixos.org/wiki/Storage_optimization#Optimising_the_store and
        # see: https://www.reddit.com/r/NixOS/comments/1cunvdw/friendly_reminder_optimizestore_is_not_on_by/
        # Optimization settings for the nix store.
        # Will optimize the nix-store on a schedule.
        optimise = {
            automatic = true;

            # See: https://wiki.nixos.org/wiki/Storage_optimization#Automation
            # MacOS: The calendar interval at which the optimiser will run.
            # See the serviceConfig.StartCalendarInterval option of
            # the launchd (nix-darwin) module for more info.
            interval = mkIf stdenv.isDarwin {
                Weekday = 0;
                Hour = 0;
                Minute = 0;
            };

            # Linux: When to run the store optimizer.
            dates = mkIf stdenv.isLinux "weekly";
        };
    };

    nixpkgs = {
        config = {
            allowUnfree = true;
            qt.enable = true;
        };
    };
}
