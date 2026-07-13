# Host identity for home-desktop — HOST-ONLY (see hosts/glorpbook/id.nix for the convention). Read
# by lib.mkNixos (as `hostId`) and flake.nix (for the nixosConfigurations attr name).
{
    hostName = "home-desktop";
    system = "x86_64-linux";
    users = [ "cogs" ];
    primaryUser = "cogs";
}
