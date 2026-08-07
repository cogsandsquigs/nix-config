# The macOS desktop. Its own file rather than a class key beside sway: the two share no configuration
# surface at all.
{

    darwin =
        {
            pkgs,
            lib,
            tools,
            config,
            ...
        }:
        {
            options.my.sys.desktop.macos.enable = tools.opt.mkEnabled "The MacOS Desktop configuration";

            config = lib.mkIf config.my.sys.desktop.macos.enable {
                # Dock configuration
                system.defaults.dock = {
                    autohide = true;
                    autohide-delay = 0.0;
                    autohide-time-modifier = 0.5;

                    # A bare /Applications path means the app comes from a Homebrew cask (see
                    # modules/apps/desktopApps.nix), so there is no store path to point at. Everything
                    # else is either a nix package or ships with macOS.
                    persistent-apps = [
                        "${pkgs.ghostty-bin}/Applications/Ghostty.app"
                        "/System/Applications/System Settings.app"
                        "/Applications/Firefox.app"
                        "${pkgs.obsidian}/Applications/Obsidian.app" # See desktop-apps
                        "/Applications/Discord.app"
                        "/System/Applications/Messages.app"
                        "/Applications/WhatsApp.app"
                        "/System/Applications/Calendar.app"
                        "/System/Applications/Reminders.app"
                        "/System/Applications/Photos.app"
                    ];
                };
            };
        };
}
