# Identity of the work-desktop host — see the `id.nix` convention in the README. A plain attrset
# (userName + hostName) that is the single source of truth for who/what this machine is. The
# builder (lib.mkHome) imports it and passes it to every module as the `hostId` argument;
# flake.nix reads it to form the homeConfigurations attribute name ("<userName>@<hostName>"); and
# scripts/rebuild.sh auto-discovers that name from the flake, so renaming the box is a one-file
# change here — nothing downstream hardcodes it.
{
    userName = "ipratt";
    hostName = "work-desktop";
}
