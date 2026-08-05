# glorpbox as a throwaway QEMU VM, for exercising the desktop before the hardware exists.
#
# Everything lives under `virtualisation.vmVariant`, which is the whole host config re-evaluated
# with qemu-vm.nix on top -- so none of it reaches `system.build.toplevel`, the real machine. The
# placeholder root filesystem and bootloader in ./default.nix need no override: qemu-vm.nix replaces
# `fileSystems` at mkVMOverride priority and boots the kernel directly, leaving systemd-boot unused.
{ lib, ... }: {
    _class = "nixos";

    virtualisation.vmVariant = {
        virtualisation = {
            memorySize = 8192;
            cores = 4;
            diskSize = 16384;

            # QEMU's default VGA exposes no DRM node, and wlroots cannot drive an output without
            # one. virtio-gpu gives it a card with dumb buffers, enough for pixman below.
            qemu.options = [ "-vga virtio" ];
        };

        # In the wrapper rather than a session variable: this runs before the compositor whatever
        # started it. No host GL to borrow, so render in software.
        programs.sway.extraSessionCommands = ''
            export WLR_RENDERER=pixman
            export WLR_NO_HARDWARE_CURSORS=1
        '';

        # Throwaway, and it lands in the store -- hence VM-only.
        users.users.cogs.initialPassword = "cogs";

        # The VM exercises the session, not the app set; these two cost gigabytes.
        home-manager.users.cogs.my.user.apps = {
            games.enable = lib.mkForce false;
            desktopApps.enable = lib.mkForce false;
        };
    };
}
