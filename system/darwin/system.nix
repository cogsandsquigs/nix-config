# Derived from https://github.com/ryan4yin/nix-darwin-kickstarter/blob/main/minimal/modules/system.nix
###################################################################################
#
#  macOS's System configuration
#
#  All the configuration options are documented here:
#    https://daiderd.com/nix-darwin/manual/index.html#sec-options
#
###################################################################################
{
    username,
    pkgs,
    config,
    ...
}:
{
    nixpkgs.hostPlatform = "aarch64-darwin";

    system = {
        primaryUser = username; # The primary user of the system

        stateVersion = 6;

        # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
        activationScripts = {
            postActivation.text = ''
                # activateSettings -u will reload the settings from the database and apply them to the current session,
                # so we do not need to logout and login again to make the changes take effect.
                # We do `sudo -u ${username}` to run the command as the user
                sudo -u ${username} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
            '';

            # NOTE: Taken from: https://github.com/nix-darwin/nix-darwin/issues/139#issuecomment-1230728610
            # WARN: See: https://github.com/nix-darwin/nix-darwin/issues/139#issuecomment-2506686625
            # and also: https://github.com/nix-darwin/nix-darwin/issues/139#issuecomment-2506899633
            #
            # ISSUE: Nix-darwin does not link installed applications to the user environment. This means apps will not show up
            # in spotlight, and when launched through the dock they come with a terminal window. This is a workaround.
            # Upstream issue: https://github.com/LnL7/nix-darwin/issues/214
            applications.text = pkgs.lib.mkForce ''
                echo "setting up ~/Applications..." >&2
                applications="$HOME/Applications"
                nix_apps="$applications/Nix Apps"

                # Needs to be writable by the user so that home-manager can symlink into it
                if ! test -d "$applications"; then
                    mkdir -p "$applications"
                    chown ${username}: "$applications"
                    chmod u+w "$applications"
                fi

                # Delete the directory to remove old links
                rm -rf "$nix_apps"
                mkdir -p "$nix_apps"
                find ${config.system.build.applications}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
                    while read -r src; do
                        # Spotlight does not recognize symlinks, it will ignore directory we link to the applications folder.
                        # It does understand MacOS aliases though, a unique filesystem feature. Sadly they cannot be created
                        # from bash (as far as I know), so we use the oh-so-great Apple Script instead.
                        /usr/bin/osascript -e "
                            set fileToAlias to POSIX file \"$src\"
                            set applicationsFolder to POSIX file \"$nix_apps\"
                            tell application \"Finder\"
                                make alias file to fileToAlias at applicationsFolder
                                # This renames the alias; 'mpv.app alias' -> 'mpv.app'
                                set name of result to \"$(rev <<< "$src" | cut -d'/' -f1 | rev)\"
                            end tell
                        " 1>/dev/null
                    done
            '';
        };

        defaults = {
            menuExtraClock.Show24Hour = false; # show 24 hour clock

            # other macOS's defaults configuration.
            # ......

            dock = {
                autohide = true;
                autohide-delay = 0.0;
                autohide-time-modifier = 0.5;
                persistent-apps = [
                    # "/System/Applications/Launchpad.app" # NOTE: Not recommended since MacOS 26!
                    "${pkgs.kitty}/Applications/kitty.app"
                    # "${pkgs.alacritty}/Applications/Alacritty.app"
                    "/System/Applications/System Settings.app"
                    # "${pkgs.firefox-unwrapped}/Applications/Firefox.app" # NOTE: See homebrew.nix for why it's `firefox-unwrapped`
                    "/Applications/Firefox.app" # NOTE: See homebrew.nix for why it's `firefox-unwrapped`
                    "${pkgs.obsidian}/Applications/Obsidian.app"
                    "${pkgs.net-news-wire}/Applications/NetNewsWire.app"
                    "${pkgs.discord}/Applications/Discord.app"
                    "${pkgs.spotify}/Applications/Spotify.app"
                    "/System/Applications/Messages.app"
                    "/Applications/WhatsApp.app" # "${pkgs.whatsapp-for-mac}/Applications/WhatsApp.app"
                    "/System/Applications/Calendar.app"
                    "/System/Applications/Reminders.app"
                    "/System/Applications/Photos.app"
                ];
            };

            SoftwareUpdate = {
                AutomaticallyInstallMacOSUpdates = true;
            };

            loginwindow.GuestEnabled = false;

            NSGlobalDomain = {
                AppleInterfaceStyle = "Dark";
            };
        };
    };

    # Add ability to used TouchID for sudo authentication
    security = {
        pam.services.sudo_local = {
            enable = true;
            touchIdAuth = true;
        };
    };
}
