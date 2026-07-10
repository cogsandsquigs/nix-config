# The `cogs` user's home-manager config — the PERSONAL unit: full personal profile (core + games +
# desktop-apps) plus the personal git identity. Self-contained: sets its own `my.user.git.*` rather
# than relying on the option defaults, so the unit stays correct wherever it's placed.
#
# Imported per-user by the wiring (home-manager.users.cogs on full-OS hosts; mkHome on standalone).
{ ... }:
{
    imports = [ ../../modules/home/personal.nix ];

    my.user.git = {
        userName = "Ian Pratt";
        email = "ianjdpratt@gmail.com";
        signingKey = "E0DB58169CA551AA!";
        signByDefault = true;
    };
}
