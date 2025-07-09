# Taken from https://github.com/ryan4yin/nix-darwin-kickstarter/blob/main/minimal/modules/nix-core.nix
{
    pkgs,
    lib,
    username,
    ...
}: let
    inherit (pkgs) stdenv;
    inherit (lib) mkIf pathExists;

    # NOTE: Since Determinate Nix is compatible with Nix-Darwin now (see
    # https://determinate.systems/posts/nix-darwin-updates/), we just deactivate
    # some settings to let determinate configure them.
    usingDeterminate =
        stdenv.isDarwin
        # && pathExists /usr/local/bin/determinate-nixd;
        # pathExists /usr/local/bin/determinate-nixd;
        ;
in {
    nix = {
        # Auto upgrade nix package and the daemon service.
        enable = !usingDeterminate;
        package = pkgs.nix;

        settings = {
            # enable flakes globally
            experimental-features = ["nix-command" "flakes"];

            # substituers that will be considered before the official ones(https://cache.nixos.org)
            substituters = [
                "https://nix-community.cachix.org"
                "https://cachix.cachix.org"
                "https://nixpkgs.cachix.org"
            ];

            # Public keys for the substituters above.
            trusted-public-keys = [
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
                "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
            ];

            trusted-users = [username];

            builders-use-substitutes = true;
            auto-optimise-store = mkIf stdenv.isLinux true;
        };

        # Collect garbage.
        # See: https://wiki.nixos.org/wiki/Storage_optimization#Garbage_collection

        gc = mkIf (!usingDeterminate) {
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
        optimise = mkIf (!usingDeterminate) {
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

    nixpkgs.config.allowUnfree = true;
}
