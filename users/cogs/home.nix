# The `cogs` user's home-manager config — the PERSONAL unit: full home library plus the personal
# selections (games + desktop-apps on) and git identity. Self-contained: sets its own
# `my.user.git.*` rather than relying on the option defaults, so the unit stays correct wherever
# it's placed.
#
# Imported per-user by the wiring (home-manager.users.cogs on full-OS hosts; mkHome on standalone).
{
    config,
    lib,
    tools,
    hostId,
    ...
}:
let
    me = "cogs@${hostId.hostName}";

    # presence of the .age is the switch — no allowlist; every machine self-wires uniformly.
    haveGpg = builtins.pathExists (../../secrets + "/${me}/gpg.age");
in
{
    imports = [ ../../modules/home ];

    my.user.games.enable = true;
    my.user.desktopApps.enable = true;

    my.user.git = {
        userName = "Ian Pratt";
        email = "ianjdpratt@gmail.com";
        signingKey = "E0DB58169CA551AA!";
        signByDefault = true;
        signingKeyFile = lib.mkIf haveGpg (tools.secrets.path config me "gpg");
    };

    age.secrets = lib.mkIf haveGpg (tools.secrets.declare me "gpg");
}
