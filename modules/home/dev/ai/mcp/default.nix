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

    # Every server rides `ai.enable` (that leaf owns programs.claude-code), so a server enabled on its
    # own would emit config nothing consumes. Fail the build instead.
    requiresAi =
        name:
        tools.opt.requires {
            when = cfg.${name}.enable;
            needs = config.my.user.dev.ai.enable;
            message = "my.user.dev.ai.mcp.${name}.enable requires my.user.dev.ai.enable";
        };
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

    # YouTrack ships its own MCP server at <instance>/mcp, so there is nothing to package: a URL and a
    # bearer header is the whole integration. Token over OAuth because this Hub advertises no
    # registration_endpoint (no dynamic client registration) and no PKCE, so OAuth would mean an
    # admin-registered confidential client plus a client secret on disk — strictly worse than a token
    # that grants the same access.
    options.my.user.dev.ai.mcp.youtrack = {
        enable = tools.opt.mkDisabled "YouTrack MCP server (issue tracking for the coding agents)";

        host = tools.opt.mkStr "\${YOUTRACK_HOST}" ''
            YouTrack host, no scheme (e.g. "youtrack.example.com"). The server URL is
            "https://<host>/mcp".
        '';
        token = tools.opt.mkStr "\${YOUTRACK_AUTH_TOKEN}" ''
            YouTrack permanent token with YouTrack scope (Profile → Account Security →
            Authentication), sent as `Authorization: Bearer <token>`. Keep it a
            `$YOUTRACK_AUTH_TOKEN` ref — a literal lands in the world-readable /nix/store.
        '';
    };

    config = lib.mkMerge [
        (lib.mkIf cfg.gerrit.enable {
            assertions = [
                (requiresAi "gerrit")
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
        })

        (lib.mkIf cfg.youtrack.enable {
            assertions = [
                (requiresAi "youtrack")
                {
                    assertion = cfg.youtrack.host != "" && cfg.youtrack.token != "";
                    message = "my.user.dev.ai.mcp.youtrack.{host,token} must not be empty";
                }
            ];

            # `type = "http"` is inferred from `url`. Claude Code expands `${VAR}` refs inside both
            # values, so host and token stay in .env.
            programs.claude-code.mcpServers.youtrack = {
                url = "https://${cfg.youtrack.host}/mcp";
                headers.Authorization = "Bearer ${cfg.youtrack.token}";
            };
        })
    ];
}
