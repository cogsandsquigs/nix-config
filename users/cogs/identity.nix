# Plain-data identity for the `cogs` user — no module args, so it can be imported anywhere
# (flake output naming, standalone home.username) without the module system. The system account
# (./system.nix) and home config (./home.nix) build on this. `username` is the portable key: the
# same unit can be placed on any host by name.
{ username = "cogs"; }
