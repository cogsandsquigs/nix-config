# Home-manager integration, shared by both the darwin and nixos hosts.
#
# The class-specific integration module (`home-manager.{darwin,nixos}Modules.home-manager`) is
# imported by each `system/<class>/default.nix`; everything here is class-agnostic and simply
# points the `cogs` user at the full personal home profile under `./home/personal.nix`.
#
# NOTE: both system hosts (MacBook, home-desktop) are personal machines, so they get the full
# profile. The work machine is a *standalone* home-manager config that does not go through this
# module at all — see lib.mkHome and hosts/work-desktop.
{ inputs, ... }: {
    home-manager = {
        verbose = true;
        useGlobalPkgs = true; # home-manager uses the system's `pkgs` (so nixpkgs config is shared)
        useUserPackages = true;
        backupFileExtension = "bak";

        extraSpecialArgs = { inherit inputs; };

        users.cogs.imports = [ ./home/personal.nix ];
    };
}
