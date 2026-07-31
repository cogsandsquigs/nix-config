# System accounts for the users this host declares (host.users, from its id.nix).
#
# Each user's account attributes live in its own portable unit at users/<name>/system.nix, so this only
# places the ones this host hosts. Home configuration for the same users flows separately, through
# modules/home-manager.nix.
#
# Identical on both system classes, so the body is written once.
let
    accounts = { host, ... }: { imports = map (name: ../users + "/${name}/system.nix") host.users; };
in
{
    nixos = accounts;
    darwin = accounts;
}
