# home-desktop — x86_64-linux NixOS tower (personal daily-driver desktop).
#
# STUB: this machine doesn't exist yet. It already inherits everything under
# modules/system/nixos + modules/home (the full personal profile: games, desktop-apps, …), so
# filling it in mostly means adding the real hardware details below. The placeholder root
# filesystem / bootloader keep the config evaluable.
#
# NOTE: this is the *personal* Linux box. The work machine is a separate, leaner standalone
# home-manager config — see hosts/work-desktop.
{ ... }: {
    nixpkgs.hostPlatform = "x86_64-linux";

    networking.hostName = "home-desktop";

    # TODO: replace with the generated ./hardware-configuration.nix once the machine is installed.
    boot.loader.systemd-boot.enable = true;
    fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
    };

    # NOTE: keep in sync with home.stateVersion the first time this box is actually installed.
    system.stateVersion = "25.05";
}
