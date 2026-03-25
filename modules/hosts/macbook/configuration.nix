{ inputs, ... }:
let
    hostname = "Ians-GlorpBook-Pro";
    primaryUser = "cogs";
in
{
    flake.modules.darwin.macbook = {
        # Specify dependencies
        imports = with inputs.self.modules.darwin; [
            desktop

            #########
            # USERS #
            #########

            cogs
        ];

        networking.hostName = hostname;
        networking.computerName = hostname;

        system = {
            # activationScripts are executed every time you boot the system or run `darwin-rebuild`.
            activationScripts = {
                postActivation.text = ''
                    # activateSettings -u will reload the settings from the database and apply them
                    # to the current session, so we do not need to logout and login again to make
                    # the changes take effect. We do `sudo -u ${primaryUser}` to run the command as the
                    # user.
                    sudo -u ${primaryUser} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
                '';
            };

            # Add ability to used TouchID for sudo authentication
            security = {
                pam.services.sudo_local = {
                    enable = true;
                    touchIdAuth = true;
                };
            };

            defaults = {
                menuExtraClock.Show24Hour = false; # show 24 hour clock
                SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
                loginwindow.GuestEnabled = false;
                NSGlobalDomain.AppleInterfaceStyle = "Dark";
                smb.NetBIOSName = hostname;
                primaryUser = primaryUser;

                dock = {
                    autohide = true;
                    autohide-delay = 0.0;
                    autohide-time-modifier = 0.5;
                    /*
                      persistent-apps = [
                          # "/System/Applications/Launchpad.app" # NOTE: Not recommended since MacOS 26!
                          "${pkgs.kitty}/Applications/kitty.app"
                          # "${pkgs.alacritty}/Applications/Alacritty.app"
                          "/System/Applications/System Settings.app"
                          # "${pkgs.firefox-unwrapped}/Applications/Firefox.app" # NOTE: See homebrew.nix for why it's `firefox-unwrapped`
                          "/Applications/Firefox.app" # NOTE: See homebrew.nix for why it's `firefox-unwrapped`
                          "${pkgs.obsidian}/Applications/Obsidian.app"
                          # "${pkgs.net-news-wire}/Applications/NetNewsWire.app"
                          "/Applications/Discord.app" # NOTE: See homebrew.nix
                          # "${pkgs.discord}/Applications/Discord.app"
                          # "${pkgs.spotify}/Applications/Spotify.app"
                          "/System/Applications/Messages.app"
                          "/Applications/WhatsApp.app" # "${pkgs.whatsapp-for-mac}/Applications/WhatsApp.app"
                          "/System/Applications/Calendar.app"

                          "/System/Applications/Reminders.app"
                          "/System/Applications/Photos.app"
                      ];
                    */
                };

            };
        };

        homebrew = {
            enable = true;
            user = primaryUser; # User owning the Homebrew prefix

            onActivation = {
                autoUpdate = true; # Auto-update
                upgrade = true; # upgrade all packages on activation / switch
                cleanup = "zap"; # 'zap': uninstalls all formulae (and related files) not listed here.
            };

            taps = [ "homebrew/services" ];

            masApps = [ ];
            brews = [ ];
            casks = [
                "firefox"
                "tailscale-app"
                "steam"
                "olympus" # Celeste mod loader
                "discord" # Req. since nix-darwin/nixpkgs discord on macos doesn't allow for notifs/screenshare (?)
                "whatsapp" # Updated more freq. than whatsapp-for-mac nix
                "porting-kit" # Windows -> Mac
                "tor-browser" # :3
            ];
            # TODO: Get rid of the above one-by-one, turning into nix pkgs.
        };
    };
}
