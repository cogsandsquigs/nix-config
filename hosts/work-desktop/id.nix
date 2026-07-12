# Host identity for work-desktop — HOST-ONLY (see hosts/glorpbook/id.nix for the convention). Read
# by lib.mkHome (as `hostId`) and flake.nix (for the homeConfigurations attr name,
# "<primaryUser>@<hostName>"). This box is standalone home-manager (per-user Nix, no system
# layer), so only its single user's home config applies; no system account is declared.
{
  hostName = "work-desktop";
  system = "x86_64-linux";
  users = [ "ipratt" ];
  primaryUser = "ipratt";
}
