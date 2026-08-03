# The typed fleet: `hosts/` and `users/` as data, checked before anything is assembled.
#
# Every `hosts/<name>/id.nix` is a submodule of the schema below, so a bad host declaration is a type
# error that names the offending option. Illegal combinations are rejected by the TYPES rather than by
# assertions:
#
#   - a user that has no `users/<name>/` directory
#   - a `primaryUser` that is not one of that host's own users
#   - a platform that contradicts the host's class (a darwin host on x86_64-linux)
#   - a `name` that disagrees with the directory (it is read-only, set from the directory)
#
# Exposes:
#   fleet.hosts.<name>     -- { name; class; system; users; primaryUser; }
{ lib, root }:
let
    dirsIn = path: lib.attrNames (lib.filterAttrs (_: t: t == "directory") (builtins.readDir path));

    userNames = dirsIn (root + "/users");
    hostNames = dirsIn (root + "/hosts");

    # Which platforms each class of host can run on.
    platforms = {
        nixos = [
            "x86_64-linux"
            "aarch64-linux"
        ];
        darwin = [
            "aarch64-darwin"
            "x86_64-darwin"
        ];
        home = [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
            "x86_64-darwin"
        ];
    };

    host = { name, config, ... }: {
        options = {
            name = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
                description = "The host's directory name, which IS its hostname. Not settable.";
            };

            class = lib.mkOption {
                type = lib.types.enum [
                    "nixos"
                    "darwin"
                    "home"
                ];
                description = ''
                    Which builder assembles this machine: a NixOS system, a nix-darwin system, or
                    a standalone home-manager configuration (per-user Nix, no system layer).
                '';
            };

            system = lib.mkOption {
                # The type depends on `class`, so a darwin host cannot claim a Linux platform.
                type = lib.types.enum platforms.${config.class};
                description = "The machine's platform (nixpkgs.hostPlatform).";
            };

            users = lib.mkOption {
                # An enum over the directories that actually exist, so a typo is a type error.
                type = lib.types.nonEmptyListOf (lib.types.enum userNames);
                description = "Which user units live on this machine.";
            };

            primaryUser = lib.mkOption {
                # An enum over this host's own users, so membership is guaranteed, not asserted.
                type = lib.types.enum config.users;
                default = lib.head config.users;
                description = ''
                    The user that owns host-level singletons (nix-darwin's system.primaryUser, the
                    Homebrew prefix). The default is all a single-user host needs.
                '';
            };
        };

        config.name = name;
    };
in
{
    hosts =
        (lib.evalModules {
            modules = [
                {
                    options.hosts = lib.mkOption {
                        type = lib.types.attrsOf (lib.types.submoduleWith { modules = [ host ]; });
                        description = "Every machine this flake builds, keyed by directory name.";
                    };
                }
                { hosts = lib.genAttrs hostNames (n: import (root + "/hosts/${n}/id.nix")); }
            ];
        }).config.hosts;
}
