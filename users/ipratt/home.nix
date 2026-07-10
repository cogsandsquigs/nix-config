# The `ipratt` user's home-manager config — the WORK unit: lean core profile only (shell, terminal,
# CLI utils, full dev toolchain), deliberately NO games/desktop-apps. Work git identity with signing
# off (no personal GPG key on the work box; to sign later import a work key and set signingKey +
# signByDefault). Self-contained wherever placed.
{ ... }:
{
    imports = [ ../../modules/home/default.nix ];

    my.user.flakeDir = "/etc/nix";

    my.user.git = {
        email = "ian.pratt@arcticlake.com";
        signingKey = null;
        signByDefault = false;
    };
}
