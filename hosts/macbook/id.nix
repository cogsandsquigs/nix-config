# Identity of the macbook host — see the `id.nix` convention in the README. A plain attrset
# (userName + hostName) that is the single source of truth for who/what this machine is. The
# builder (lib.mkDarwin) imports it and passes it to every module as the `hostId` argument, and
# flake.nix reads it to form the darwinConfigurations attribute name.
{
    userName = "cogs";
    hostName = "Ians-GlorpBook-Pro";
}
