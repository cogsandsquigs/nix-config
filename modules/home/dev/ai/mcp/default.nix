# MCP servers for the coding agents. One leaf per server under `my.user.dev.ai.mcp.<name>`, opt-in
# since each talks to a private service that only exists on some machines.
#
# Credential defaults are `${VAR}` refs, expanded by Claude Code from its own env at launch (`.env` is
# sourced with `set -a` at shell startup). A literal here would land in the world-readable
# /nix/store.
{
    lib,
    tools,
    config,
    pkgs,
    ...
}:
let
    cfg = config.my.user.dev.ai.mcp;

    # The Gerrit project's own server (./gerrit.nix). Picked over the third-party ones as the only one
    # that can *read* — query changes, list comments, read votes — so an agent can work through review
    # feedback, not just post it. It reads /comments, not /robotcomments, so analyzer *plugin*
    # comments (as opposed to bot accounts) are invisible.
    gerritMcp = pkgs.callPackage ./gerrit.nix { };
in
{
    options.my.user.dev.ai.mcp.gerrit = {
        enable = tools.opt.mkDisabled "Gerrit MCP server (code review tools for the coding agents)";

        host = tools.opt.mkStr "\${GERRIT_HOST}" ''Gerrit host, no scheme (e.g. "gerrit.example.com").'';
        username = tools.opt.mkStr "\${GERRIT_USERNAME}" "Gerrit account username.";
        password = tools.opt.mkStr "\${GERRIT_PASSWORD}" ''
            Gerrit HTTP password (Settings → HTTP Credentials). Keep it a `$GERRIT_PASSWORD` ref — a
            literal lands in the world-readable /nix/store.
        '';
    };

    config = lib.mkIf cfg.gerrit.enable {
        assertions = [
            # Gated on this leaf, not `ai.enable`, so a mis-wire fails the build instead of silently
            # emitting no MCP config.
            (tools.opt.requires {
                when = cfg.gerrit.enable;
                needs = config.my.user.dev.ai.enable;
                message = "my.user.dev.ai.mcp.gerrit.enable requires my.user.dev.ai.enable";
            })
            {
                assertion = cfg.gerrit.host != "" && cfg.gerrit.username != "" && cfg.gerrit.password != "";
                message = "my.user.dev.ai.mcp.gerrit.{host,username,password} must not be empty";
            }
        ];

        # home-manager infers `type = "stdio"` from `command` (lib.hm.mcp.addType).
        programs.claude-code.mcpServers.gerrit = {
            command = "${gerritMcp}/bin/gerrit-mcp";
            env = {
                GERRIT_HOST = cfg.gerrit.host;
                GERRIT_USERNAME = cfg.gerrit.username;
                GERRIT_PASSWORD = cfg.gerrit.password;
            };
        };
    };
}
