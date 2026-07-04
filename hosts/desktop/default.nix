# desktop — x86_64-linux NixOS tower.
#
# STUB: this machine doesn't exist yet. It already inherits everything under
# modules/system/nixos + modules/home, so filling it in mostly means adding the real hardware
# details below. The placeholder root filesystem / bootloader keep the config evaluable.
{ ... }: {
    nixpkgs.hostPlatform = "x86_64-linux";

    networking.hostName = "desktop";

    # TODO: replace with the generated ./hardware-configuration.nix once the machine is installed.
    boot.loader.systemd-boot.enable = true;
    fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
    };

    # NOTE: keep in sync with home.stateVersion the first time this box is actually installed.
    system.stateVersion = "25.05";
}
