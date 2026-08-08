# glorpbox -- x86_64-linux NixOS tower (personal daily-driver desktop).
#
# STUB: this machine does not exist yet. It already inherits every feature under modules/ (the full
# personal profile), so filling it in means adding the real hardware details below. The placeholder root
# filesystem and bootloader are what keep it evaluable meanwhile.
#
# The *personal* Linux box. The work machine is a leaner standalone home-manager config -- hosts/ip-workbox.
{ host, ... }: {
    _class = "nixos";

    # VM-only knobs, so `nix build .#glorpbox-vm` boots something usable. All of it sits under
    # `virtualisation.vmVariant`, so none can reach the real machine.
    imports = [ ./vm.nix ];

    nixpkgs.hostPlatform = host.system;

    # Hostname is the host directory's name -- see tools/fleet.nix.
    networking.hostName = host.name;

    # TODO: replace with the generated ./hardware-configuration.nix once the machine is installed.
    boot.loader.systemd-boot.enable = true;
    fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
    };

    # NOTE: keep in sync with home.stateVersion the first time this box is actually installed.
    system.stateVersion = "25.05";
}
