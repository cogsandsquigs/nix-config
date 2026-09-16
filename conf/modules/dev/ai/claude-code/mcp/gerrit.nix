# Gerrit MCP server -- GerritCodeReview/gerrit-mcp-server, packaged in ./_gerrit-package.nix.
#
# Picked over the third-party ones as the only one that can *read* -- query changes, list comments,
# read votes -- so an agent can work through review feedback, not just post it. It reads /comments,
# not /robotcomments, so analyzer *plugin* comments (as opposed to bot accounts) are invisible.
{
    home =
        {
            lib,
            tools,
            config,
            options,
            pkgs,
            ...
        }:
        let
            mcp = config.my.user.dev.ai.claude-code.mcp;
            cfg = mcp.gerrit;

            gerritMcp = pkgs.callPackage ./_gerrit-package.nix { };
        in
        {
            options.my.user.dev.ai.claude-code.mcp.gerrit = {
                enable = tools.opt.mkDisabled "Gerrit MCP server (code review tools for Claude Code)";

                host = tools.opt.mkNonEmptyStr "\${GERRIT_HOST}" ''Gerrit host, no scheme (e.g. "gerrit.example.com").'';
                username = tools.opt.mkNonEmptyStr "\${GERRIT_USERNAME}" "Gerrit account username.";
                password = tools.opt.mkNonEmptyStr "\${GERRIT_PASSWORD}" ''
                    Gerrit HTTP password (Settings -> HTTP Credentials). Keep it a `$GERRIT_PASSWORD` ref -- a
                    literal lands in the world-readable /nix/store.
                '';
            };

            config = lib.mkIf (mcp.enable && cfg.enable) {
                assertions = [
                    (tools.opt.dependsOn {
                        feature = options.my.user.dev.ai.claude-code.mcp.gerrit.enable;
                        dependency = options.my.user.dev.ai.claude-code.enable;
                    })
                ];

                # home-manager infers `type = "stdio"` from `command` (lib.hm.mcp.addType).
                programs.claude-code.mcpServers.gerrit = {
                    command = "${gerritMcp}/bin/gerrit-mcp";
                    env = {
                        GERRIT_HOST = cfg.host;
                        GERRIT_USERNAME = cfg.username;
                        GERRIT_PASSWORD = cfg.password;
                    };
                };
            };
        };
}
