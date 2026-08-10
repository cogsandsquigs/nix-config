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

    # Credentials come from GERRIT_* / YOUTRACK_* in ${flakeDir}/.env, expanded by Claude Code at
    # launch (see modules/dev/ai/mcp).
    my.user.dev.ai.mcp.gerrit.enable = true;
    my.user.dev.ai.mcp.youtrack.enable = true;
    my.user.dev.ai.mcp.notify.enable = true;
}
