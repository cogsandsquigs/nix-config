# Home-manager integration, shared by both the darwin and nixos hosts.
#
# The class-specific integration module (`home-manager.{darwin,nixos}Modules.home-manager`) is
# imported by each `system/<class>/default.nix`; everything here is class-agnostic and simply
# points the host's primary user (from its id.nix, via the `hostId` specialArg) at the full
# personal home profile under `./home/personal.nix`.
#
# NOTE: both system hosts (MacBook, home-desktop) are personal machines, so they get the full
# profile. The work machine is a *standalone* home-manager config that does not go through this
# module at all — see lib.mkHome and hosts/work-desktop.
{ inputs, hostId, ... }: {
    home-manager = {
        verbose = true;
        useGlobalPkgs = true; # home-manager uses the system's `pkgs` (so nixpkgs config is shared)
        useUserPackages = true;
        backupFileExtension = "bak";

        extraSpecialArgs = { inherit inputs hostId; };

        users.${hostId.userName}.imports = [ ./home/personal.nix ];
    };
}
