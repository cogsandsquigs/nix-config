# glorpbook -- aarch64-darwin MacBook.
# This file owns the machine's identity and host-only tweaks; every shared feature lives under modules/.
{ pkgs, host, ... }:
let
    # Host identity comes from ./id.nix via the `host` specialArg, checked by tools/fleet.nix. The
    # hostname is the directory name; `primaryUser` owns host-level singletons (system.primaryUser,
    # the Homebrew prefix).
    hostName = host.name;
    inherit (host) primaryUser;
in
{
    _class = "darwin";

    nixpkgs.hostPlatform = host.system;

    # `games` and `desktopApps` follow the users on this host, so only the genuinely host-level
    # opt-ins are named here.
    my.sys = {
        darwin.fuse.enable = true;
        net = {
            tailscale.enable = true;
            openvpn.enable = true;
        };
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
        inherit primaryUser;

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

                # A bare /Applications path means the app comes from a Homebrew cask (see
                # modules/apps/desktopApps.nix), so there is no store path to point at. Everything
                # else is either a nix package or ships with macOS.
                persistent-apps = [
                    "${pkgs.ghostty-bin}/Applications/Ghostty.app"
                    "/System/Applications/System Settings.app"
                    "/Applications/Firefox.app"
                    # "${pkgs.obsidian}/Applications/Obsidian.app" # See desktop-apps
                    "${pkgs.discord}/Applications/Discord.app"
                    "/System/Applications/Messages.app"
                    "/Applications/WhatsApp.app"
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
    };
}
