# Home-manager integration for the full-OS hosts.
#
# Points each user the host declares (host.users, from its id.nix) at users/<name>/home.nix and hands the
# home registry to the sub-evaluation. The user unit decides the feature set, which is what keeps users
# portable across hosts.
#
# A standalone home-manager host has no system layer and never reaches this file. tools/default.nix builds
# it directly from the user unit.
#
# Identical on both system classes apart from which integration module to import, so the body is written
# once.
let
    integration =
        {
            host,
            lib,
            registry,
            moduleArgs,
            ...
        }:
        {
            home-manager = {
                verbose = true;
                useGlobalPkgs = true; # home-manager uses the system's `pkgs`, so nixpkgs config is shared
                useUserPackages = true;
                backupFileExtension = "bak";

                # The sub-evaluation does not inherit the parent's specialArgs, so this forward is
                # irreducible. Passing `moduleArgs` -- the set tools/default.nix built -- gives a home
                # module the same argument surface on a system host and a standalone box by construction,
                # rather than by two lists agreeing.
                extraSpecialArgs = moduleArgs;

                users = lib.genAttrs host.users (name: {
                    imports = lib.attrValues registry.homeManager ++ [ (../../users + "/${name}/home.nix") ];
                });
            };
        };
in
{
    nixos = { inputs, ... }: {
        imports = [
            inputs.home-manager.nixosModules.home-manager
            integration
        ];
    };

    darwin = { inputs, ... }: {
        imports = [
            inputs.home-manager.darwinModules.home-manager
            integration
        ];
    };
}
