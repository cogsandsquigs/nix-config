{ inputs, ... }:
let

    # Derive Apple locale strings from the keyboard locale.
    # "en_GB.UTF-8" -> "en_GB" (strip encoding suffix)
    # "en_GB" -> "en-GB" (Apple language tag uses hyphens)
    #appleLocale = lib.head (lib.splitString "." host.keyboard.locale);
    appleLocale = "en_US";
    appleLanguage = builtins.replaceStrings [ "_" ] [ "-" ] appleLocale;
in
{

    # default settings needed for all darwinConfigurations
    flake.modules.darwin.base =
        { pkgs, ... }:
        {
            imports = with inputs.self.modules.darwin; [
                determinate
                overlays
            ];

            system.stateVersion = 6;
            system.defaults = {
                menuExtraClock.Show24Hour = false; # show 24 hour clock
                SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
                loginwindow.GuestEnabled = false;
                NSGlobalDomain.AppleInterfaceStyle = "Dark";
                CustomUserPreferences = {
                    "com.apple.AdLib" = {
                        allowApplePersonalizedAdvertising = false;
                    };
                    "com.apple.controlcenter" = {
                        BatteryShowPercentage = true;
                    };
                    "com.apple.desktopservices" = {
                        # Avoid creating .DS_Store files on network or USB volumes
                        DSDontWriteNetworkStores = true;
                        DSDontWriteUSBStores = true;
                    };
                    "com.apple.finder" = {
                        _FXSortFoldersFirst = true;
                        FXDefaultSearchScope = "SCcf"; # Search current folder by default
                        ShowExternalHardDrivesOnDesktop = true;
                        ShowHardDrivesOnDesktop = false;
                        ShowMountedServersOnDesktop = true;
                        ShowRemovableMediaOnDesktop = true;
                    };
                    # Prevent Photos from opening automatically
                    "com.apple.ImageCapture".disableHotPlug = true;
                    "com.apple.screencapture" = {
                        location = "~/Pictures/Screenshots";
                        type = "png";
                    };
                    "com.apple.SoftwareUpdate" = {
                        AutomaticCheckEnabled = true;
                        # Check for software updates daily, not just once per week
                        ScheduleFrequency = 1;
                        # Download newly available updates in background
                        AutomaticDownload = 0;
                        # Install System data files & security updates
                        CriticalUpdateInstall = 1;
                    };
                    "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
                    # Turn on app auto-update
                    "com.apple.commerce".AutoUpdate = true;
                    NSGlobalDomain = {
                        AppleLanguages = [ appleLanguage ];
                        AppleLocale = appleLocale;
                    };
                };
            };

            environment.systemPackages =
                with inputs.nix-darwin.packages.${pkgs.stdenv.hostPlatform.system};
                with pkgs;
                [
                    # Nix-darwin pkgs
                    darwin-option
                    darwin-rebuild
                    darwin-version
                    darwin-uninstaller

                    # Regular, base pkgs
                    mkalias # TODO: Why?
                    openssl # TODO: Why?
                ];

        };
}
