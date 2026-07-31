# Home-manager integration for the full-OS hosts, shared by the darwin and nixos classes.
#
# The class-specific integration module (`home-manager.{darwin,nixos}Modules.home-manager`) is
# imported by each `system/<class>/default.nix`; everything here is class-agnostic and points each user
# the host declares (host.users, from its id.nix) at that user's home unit under
# `../users/<name>/home.nix`. The user unit -- not this module -- decides the feature set (personal vs
# work, ...), keeping users isolated and portable across hosts.
#
# A standalone home-manager host has no system layer, so it never reaches this file: tools/default.nix
# builds it directly from the user unit.
{
    host,
    lib,
    moduleArgs,
    ...
}:
{
    home-manager = {
        verbose = true;
        useGlobalPkgs = true; # home-manager uses the system's `pkgs`, so nixpkgs config is shared
        useUserPackages = true;
        backupFileExtension = "bak";

        # The sub-evaluation does not inherit the parent's specialArgs, so the forward is irreducible.
        # Handing it `moduleArgs` -- the same set tools/default.nix built -- means a home module sees an
        # identical argument surface on a system host and on a standalone box, by construction rather
        # than by two lists agreeing.
        extraSpecialArgs = moduleArgs;

        users = lib.genAttrs host.users (name: {
            imports = [ (../users + "/${name}/home.nix") ];
        });
    };
}
