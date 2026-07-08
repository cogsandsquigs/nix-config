# Identity of the home-desktop host — see the `id.nix` convention in the README. A plain attrset
# (userName + hostName) that is the single source of truth for who/what this machine is. The
# builder (lib.mkNixos) imports it and passes it to every module as the `hostId` argument, and
# flake.nix reads it to form the nixosConfigurations attribute name.
{
    userName = "cogs";
    hostName = "home-desktop";
}
