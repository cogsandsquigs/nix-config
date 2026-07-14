# Home-manager integration, shared by both the darwin and nixos hosts.
#
# The class-specific integration module (`home-manager.{darwin,nixos}Modules.home-manager`) is
# imported by each `system/<class>/default.nix`; everything here is class-agnostic and points each
# user the host declares (hostId.users, from its id.nix) at that user's home unit under
# `../users/<name>/home.nix`. The user unit — not this module — decides the feature set (personal
# vs work, …), keeping users isolated and portable across hosts.
{
    inputs,
    hostId,
    lib,
    tools,
    ...
}:
{
    home-manager = {
        verbose = true;
        useGlobalPkgs = true; # home-manager uses the system's `pkgs` (so nixpkgs config is shared)
        useUserPackages = true;
        backupFileExtension = "bak";

        # Forward our `tools` helpers into the home-manager sub-eval, so home feature modules get
        # the same option/safety helpers the system modules do. (HM's sub-eval doesn't inherit the
        # parent specialArgs, so this forward is necessary — irreducible.)
        extraSpecialArgs = { inherit inputs hostId tools; };

        fonts.fontconfig = {
            enable = true;
        };

        users = lib.genAttrs hostId.users (name: {
            imports = [ (../users + "/${name}/home.nix") ];
        });
    };
}
