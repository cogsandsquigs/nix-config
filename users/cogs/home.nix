# The `cogs` user's home-manager config -- the PERSONAL unit.
#
# Every feature under modules/ is already loaded by the registry, so this unit is pure selection: which
# optional features to turn on, and this user's own values. It sets `my.user.cli.git.*` explicitly rather
# than relying on the option defaults, so the unit stays correct wherever it is placed.
{
    config,
    lib,
    tools,
    host,
    ...
}:
let
    me = "cogs@${host.name}";

    # presence of the .sops file is the switch -- no allowlist. Every machine self-wires uniformly.
    haveGpg = builtins.pathExists (../../secrets + "/${me}/gpg.sops");
in
{
    my.user.apps.games.enable = true;
    my.user.apps.desktopApps.enable = true;
    my.user.apps.desktopUtils.enable = true;

    # Rides the host's class rather than a flat `true`: the sway binary comes from the system half,
    # which only a NixOS host has. The system half then follows this back (mkFollowsUsers).
    my.user.desktop.sway.enable = host.class == "nixos";

    my.user.cli.git = {
        userName = "Ian Pratt";
        email = "ianjdpratt@gmail.com";
        signingKey = "E0DB58169CA551AA!";
        signByDefault = true;
        signingKeyFile = lib.mkIf haveGpg (tools.secrets.path config me "gpg");
    };

    my.user.dev.ai = {
        omp.enable = true;
    };

    sops.secrets = lib.mkIf haveGpg (tools.secrets.declare me "gpg");
}
