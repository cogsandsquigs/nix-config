# The `ipratt` user's home-manager config -- the WORK unit.
#
# Leaves the optional features (games, desktopApps) off, so this user gets the core set only: shell,
# terminal, CLI utilities and the full dev toolchain. Work git identity with signing off, because there
# is no personal GPG key on the work box -- to sign later, import a work key and set `signingKey` and
# `signByDefault`.
_: {
    my.user.shell.flakeDir = "/etc/nix";

    my.user.cli.git = {
        email = "ian.pratt@arcticlake.com";
        signingKey = null;
        signByDefault = false;
    };

    # my.user.dev.editors.vscode.enable = true;

    ## Coding agents. One block per harness: the shared payload -- instructions and the portable skills
    ## -- needs nothing said here, so everything below is a per-harness switch.
    my.user.dev.ai = {
        claude-code = {
            # Credentials come from GERRIT_* / YOUTRACK_* in ${flakeDir}/.env, expanded by Claude Code
            # at launch (see modules/dev/ai/claude-code/mcp).
            mcp = {
                gerrit.enable = true;
                youtrack.enable = true;
                notify.enable = true;
            };

            # Pins the 5h window's boundaries at 10:30 / 15:30 (modules/dev/ai/claude-code/ping.nix).
            ping.enable = true;
        };
    };
}
