{username, ...}: {
    # NOTE: Since `homebrew` is not managed by home-manager, we need to include
    # in in the system-wide configuration for `darwin` systems. So, it's here.
    # Oh well ¯\_(ツ)_/¯
    homebrew = {
        enable = true;

        user = username; # User owning the Homebrew prefix

        onActivation = {
            autoUpdate = true; # Auto-update
            upgrade = true; # upgrade all packages on activation / switch
            cleanup = "zap"; # 'zap': uninstalls all formulae(and related files) not listed here.
        };

        taps = [
            "homebrew/services"
        ];

        # MacOS App Store apps.
        # NOTE: You need the App ID to install apps from the App Store. Can be found on the app's page URL
        # on the App Store.
        masApps = {
            #"Xcode" = 497799835; # NOTE: Worst idea to automate this EVER. Why does xcode take so long :'(
        };

        # `brew install`
        brews = [
            "ca-certificates" # NOTE: For some reason this is required by `bun` and also some others
        ];

        # `brew install --cask`
        # TODO Feel free to add your favorite apps here.
        casks = [
            "firefox"
            "tailscale"
            "steam"
            "olympus" # Celeste mod loader
            "tomatobar" # Pomorodro timer
            "roblox"
        ];
    };
}
