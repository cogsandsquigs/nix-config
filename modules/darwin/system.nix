# Derived from https://github.com/ryan4yin/nix-darwin-kickstarter/blob/main/minimal/modules/system.nix
{
  pkgs,
  platform,
  ...
}:
###################################################################################
#
#  macOS's System configuration
#
#  All the configuration options are documented here:
#    https://daiderd.com/nix-darwin/manual/index.html#sec-options
#
###################################################################################
let
  username = "ianpratt";
  platform = "aarch64-darwin"; # aarch64-darwin or x86_64-darwin
  hostname = "Ians-GlorpBook-Pro";
in {
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
          "/Applications/Nix Apps/kitty.app"
          "/System/Applications/System Settings.app"
          "/Applications/Firefox.app"
          "/Applications/Obsidian.app"
          "/Applications/Nix Apps/NetNewsWire.app"
          "/Applications/Nix Apps/Discord.app"
          "/System/Applications/Messages.app"
          "/Applications/WhatsApp.app"
          "/System/Applications/Calendar.app"
          "/System/Applications/Reminders.app"
          "/System/Applications/Photos.app"
        ];
      };
    };
  };

  nixpkgs.hostPlatform = platform;

  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;
}
