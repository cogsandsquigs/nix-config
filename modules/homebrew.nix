# modules/homebrew.nix
# Homebrew via nix-darwin. Brew itself must already be installed (or use nix-homebrew).
# Individual modules (e.g. games/steam) just append to `homebrew.casks`; lists merge.
{ config, ... }: {
    flake.modules.darwin.homebrew = {
        homebrew = {
            enable = true;
            user = config.me.username;

            onActivation = {
                # autoUpdate = false; # keep rebuilds reproducible
                # upgrade = false;
                # cleanup = "none"; # "zap" would remove anything not declared

                autoUpdate = true;
                upgrade = true;
                cleanup = "zap";
            };

            taps = [ "homebrew/services" ];
        };
    };
}
