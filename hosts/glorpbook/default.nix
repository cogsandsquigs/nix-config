# glorpbook — aarch64-darwin MacBook.
# This file owns the machine's identity and host-only tweaks; everything shared lives under
# modules/system/darwin and modules/home.
{ pkgs, hostId, ... }:
let
  # Host identity (hostname, platform, primary user) comes from ./id.nix via the hostId
  # specialArg — see the README `id.nix` convention. `primaryUser` owns host-level singletons
  # (system.primaryUser, the Homebrew prefix).
  inherit (hostId) hostName primaryUser;
in
{
  imports = [ ./launchd.nix ];

  nixpkgs.hostPlatform = hostId.system;

  # Optional system features this host opts into (all default off in the modules).
  my.sys = {
    games.enable = true;
    desktopApps.enable = true;
    fuse.enable = true;
  };

  networking.hostName = hostName;
  networking.computerName = hostName;

  # Add ability to used TouchID for sudo authentication
  security = {
    pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true;
      watchIdAuth = true;
    };
  };

  system = {
    primaryUser = primaryUser;

    # activationScripts are executed every time you boot the system or run `darwin-rebuild`.
    activationScripts = {
      postActivation.text = ''
        # activateSettings -u will reload the settings from the database and apply them
        # to the current session, so we do not need to logout and login again to make
        # the changes take effect. We do `sudo -u ${primaryUser}` to run the command as
        # the user.
        sudo -u ${primaryUser} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      '';
    };

    defaults = {
      smb.NetBIOSName = hostName;
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.5;

        persistent-apps = [
          "${pkgs.kitty}/Applications/kitty.app"
          "/System/Applications/System Settings.app"
          # "${pkgs.firefox-unwrapped}/Applications/Firefox.app" # NOTE: See homebrew.nix for why it's `firefox-unwrapped`
          "/Applications/Firefox.app" # NOTE: See homebrew.nix for why it's `firefox-unwrapped`
          "${pkgs.obsidian}/Applications/Obsidian.app"
          "${pkgs.discord}/Applications/Discord.app"
          "/System/Applications/Messages.app"
          "/Applications/WhatsApp.app" # "${pkgs.whatsapp-for-mac}/Applications/WhatsApp.app"
          "/System/Applications/Calendar.app"
          "/System/Applications/Reminders.app"
          "/System/Applications/Photos.app"
        ];

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

    #masApps = [ ];
    #brews = [ ];
    #casks = [ "tailscale-app" ];
    # TODO: Get rid of the above one-by-one, turning into nix pkgs.
  };
}
