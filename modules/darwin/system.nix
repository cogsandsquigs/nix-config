# Derived from https://github.com/ryan4yin/nix-darwin-kickstarter/blob/main/minimal/modules/system.nix
{pkgs, ...}:
###################################################################################
#
#  macOS's System configuration
#
#  All the configuration options are documented here:
#    https://daiderd.com/nix-darwin/manual/index.html#sec-options
#
###################################################################################
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  system = {
    stateVersion = 6;
    # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
    activationScripts.postUserActivation.text = ''
      # activateSettings -u will reload the settings from the database and apply them to the current session,
      # so we do not need to logout and login again to make the changes take effect.
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

    defaults = {
      menuExtraClock.Show24Hour = false; # show 24 hour clock

      # other macOS's defaults configuration.
      # ......

      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.5;
        persistent-apps = [
          "/System/Applications/Launchpad.app"
          "${pkgs.kitty}/Applications/kitty.app"
          "/System/Applications/System Settings.app"
          "/Applications/Firefox.app"
          "${pkgs.obsidian}/Applications/Obsidian.app"
          "${pkgs.net-news-wire}/Applications/NetNewsWire.app"
          "${pkgs.discord}/Applications/Discord.app"
          "/System/Applications/Messages.app"
          "/Applications/WhatsApp.app"
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
    pam.enableSudoTouchIdAuth = true;
  };
}
