# YouTrack MCP server. It ships its own server at <instance>/mcp, so there is nothing to package: a
# URL and a bearer header is the whole integration.
#
# Token over OAuth because this Hub advertises no registration_endpoint (no dynamic client
# registration) and no PKCE, so OAuth would mean an admin-registered confidential client plus a
# client secret on disk — strictly worse than a token that grants the same access.
{
    lib,
    tools,
    config,
    ...
}:
let
    cfg = config.my.user.dev.ai.mcp.youtrack;
in
{
    options.my.user.dev.ai.mcp.youtrack = {
        enable = tools.opt.mkDisabled "YouTrack MCP server (issue tracking for the coding agents)";

        host = tools.opt.mkNonEmptyStr "\${YOUTRACK_HOST}" ''
            YouTrack host, no scheme (e.g. "youtrack.example.com"). The server URL is
            "https://<host>/mcp".
        '';
        token = tools.opt.mkNonEmptyStr "\${YOUTRACK_AUTH_TOKEN}" ''
            YouTrack permanent token with YouTrack scope (Profile → Account Security →
            Authentication), sent as `Authorization: Bearer <token>`. Keep it a
            `$YOUTRACK_AUTH_TOKEN` ref — a literal lands in the world-readable /nix/store.
        '';
    };

    config = lib.mkIf cfg.enable {
        assertions = [
            (tools.opt.requires {
                when = cfg.enable;
                needs = config.my.user.dev.ai.enable;
                message = "my.user.dev.ai.mcp.youtrack.enable requires my.user.dev.ai.enable";
            })
        ];

        # `type = "http"` is inferred from `url`. Claude Code expands `${VAR}` refs inside both
        # values, so host and token stay in .env.
        programs.claude-code.mcpServers.youtrack = {
            url = "https://${cfg.host}/mcp";
            headers.Authorization = "Bearer ${cfg.token}";
        };
    };
}
