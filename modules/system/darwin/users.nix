# System accounts for the users this host declares — see modules/system/nixos/users.nix for the
# convention. Each user's account attrs live in users/<name>/system.nix (class-portable).
{ hostId, ... }: { imports = map (name: ../../../users + "/${name}/system.nix") hostId.users; }
