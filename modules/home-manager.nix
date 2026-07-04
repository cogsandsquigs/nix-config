# Home-manager integration, shared by both the darwin and nixos hosts.
#
# The class-specific integration module (`home-manager.{darwin,nixos}Modules.home-manager`) is
# imported by each `system/<class>/default.nix`; everything here is class-agnostic and simply
# points the `cogs` user at the shared home configuration under `./home`.
{ inputs, ... }: {
    home-manager = {
        verbose = true;
        useGlobalPkgs = true; # home-manager uses the system's `pkgs` (so nixpkgs config is shared)
        useUserPackages = true;
        backupFileExtension = "bak";

        extraSpecialArgs = { inherit inputs; };

        users.cogs.imports = [ ./home ];
    };
}
