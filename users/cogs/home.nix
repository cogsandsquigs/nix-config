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

    # presence of the .sops file is the switch -- no allowlist; every machine self-wires uniformly.
    haveGpg = builtins.pathExists (../../secrets + "/${me}/gpg.sops");
in
{
    my.user.apps.games.enable = true;
    my.user.apps.desktopApps.enable = true;

    my.user.cli.git = {
        userName = "Ian Pratt";
        email = "ianjdpratt@gmail.com";
        signingKey = "E0DB58169CA551AA!";
        signByDefault = true;
        signingKeyFile = lib.mkIf haveGpg (tools.secrets.path config me "gpg");
    };

    sops.secrets = lib.mkIf haveGpg (tools.secrets.declare me "gpg");
}
