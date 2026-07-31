# Personal GUI applications, on the classes that have any.
#
# The split is by what installs reliably where: nixpkgs for the cross-platform apps, Homebrew casks on
# macOS for the ones whose nixpkgs builds lag upstream or do not exist.
#
# The filename is camelCase because a feature may only declare options under the path its own path
# owns, and this one owns `my.{user,sys}.desktopApps`. See the `feature-paths` check.
{
    home =
        {
            pkgs,
            lib,
            config,
            tools,
            ...
        }:
        {
            options.my.user.apps.desktopApps.enable =
                tools.opt.mkDisabled "personal GUI apps (Discord, Obsidian, Zoom, ...)";

            config = lib.mkIf config.my.user.apps.desktopApps.enable {
                home.packages = with pkgs; [
                    # Productivity
                    discord # currently on macos gets stuck on launch, keeps trying 2 upd (???) ptb and canary don't fix issue
                    obsidian
                    zoom-us
                    qbittorrent

                    # Fun
                    #spotify
                ];
            };
        };

    darwin =
        {
            lib,
            config,
            tools,
            ...
        }:
        {
            options.my.sys.apps.desktopApps.enable = tools.opt.mkFollowsUsers config [
                "apps"
                "desktopApps"
            ] "GUI apps via Homebrew (WhatsApp, Firefox).";

            config = lib.mkIf config.my.sys.apps.desktopApps.enable {
                homebrew = {
                    casks = [
                        "whatsapp" # Updated more freq. than whatsapp-for-mac nix
                        "firefox"
                        "ungoogled-chromium"
                        #"google-drive" # Google drive GUI client
                    ];
                };
            };
        };
}
