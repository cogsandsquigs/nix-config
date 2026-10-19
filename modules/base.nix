# The base NixOS / Nix-Darwin configuration all devices share. This file is intended for modifying
# basal, shared things things only, and NOT for style / packages / etc. Those should be set
# elsewhere, and then included (imported) here if it is a "base" item.
{ self, config,... }: {
    flake.modules.nixos.base = {
        imports = [
            self.modules.nixos.nix
            self.modules.nixos.fonts
            self.modules.nixos.shell
            self.modules.nixos.home-manager
        ];

        users.defaultUserShell = pkgs.fish;
    };

    flake.modules.darwin.base = {
        imports = [
            self.modules.darwin.nix
            self.modules.darwin.fonts
            self.modules.darwin.shell
            self.modules.darwin.home-manager

            # darwin-only
            self.modules.darwin.homebrew
            self.modules.darwin."apps/browsers"
            self.modules.darwin."apps/messaging"
        ];

        # Add ability to used TouchID for sudo authentication
        security = {
            pam.services.sudo_local = {
                enable = true;
                touchIdAuth = true;
                watchIdAuth = true;
            };

            users.users.${config.me.username}.shell = pkgs.fish;
        };
    };
}

/*
  # glorpbook -- aarch64-darwin MacBook.
  # This file owns the machine's identity and host-only tweaks. Every shared feature lives under conf/modules/.
  { host, ... }:
  let
      # Host identity comes from ./id.nix via the `host` specialArg, checked by lib/tools/fleet.nix.
      # The hostname is the directory name. `primaryUser` owns host-level singletons (system.primaryUser,
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
              openvpn.enable = false;
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
*/
