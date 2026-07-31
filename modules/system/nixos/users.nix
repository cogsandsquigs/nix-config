# System accounts for the users this host declares (host.users, from its id.nix). Each user's account
# attrs live in its own portable unit at users/<name>/system.nix; here we just import the ones this
# host hosts. Home config for the same users flows separately via modules/home-manager.nix.
{ host, ... }: { imports = map (name: ../../../users + "/${name}/system.nix") host.users; }
