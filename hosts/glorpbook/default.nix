# glorpbook -- aarch64-darwin MacBook.
# This file owns the machine's identity and host-only tweaks. Every shared feature lives under modules/.
{ host, ... }:
let
    # Host identity comes from ./id.nix via the `host` specialArg, checked by tools/fleet.nix. The
    # hostname is the directory name. `primaryUser` owns host-level singletons (system.primaryUser,
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
        os.darwin.fuse.enable = true;
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

        defaults = {
            smb.NetBIOSName = hostName;
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
