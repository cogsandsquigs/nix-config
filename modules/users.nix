# System accounts for the users this host declares (host.users, from its id.nix).
#
# Each user's account attributes live in its own portable unit at users/<name>/system.nix, keyed by
# class for the same reason a feature is: the two classes accept different attributes. This selects the
# half that matches, so a NixOS host never sees the darwin account and the reverse.
#
# Home configuration for the same users flows separately, through modules/home-manager.nix.
let
    accountsFor = class: { host, ... }: {
        imports = map (name: (import (../users + "/${name}/system.nix")).${class}) host.users;
    };
in
{
    nixos = accountsFor "nixos";
    darwin = accountsFor "darwin";
}
