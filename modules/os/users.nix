# System accounts for the users this host declares (host.users, from its id.nix).
#
# Account attributes live in the portable unit at users/<name>/system.nix, keyed by class because the two
# classes accept different attributes. This selects the matching half. Home configuration for the same
# users flows separately, through modules/os/home-manager.nix.
let
    accountsFor = class: { host, ... }: {
        imports = map (name: (import (../../users + "/${name}/system.nix")).${class}) host.users;
    };
in
{
    nixos = accountsFor "nixos";
    darwin = accountsFor "darwin";
}
