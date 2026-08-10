# Desktop notifications: a `notify` tool the agent can call, packaged in ./_notify-package.nix, plus the
# Claude Code Notification hook calling that same tool when Claude wants you.
#
# The one server here that talks to no private service, so it needs no credentials and rides no `.env`.
#
# The hook ships as a PLUGIN, not through `programs.claude-code.settings`. Setting `settings` at all
# makes home-manager write ~/.claude/settings.json, which Claude Code mutates itself -- `/model`,
# `/config`, theme and enabledPlugins all write there, and a read-only store symlink breaks every one.
{
    home =
        {
            lib,
            tools,
            config,
            pkgs,
            ...
        }:
        let
            mcp = config.my.user.dev.ai.mcp;
            cfg = mcp.notify;

            notifyMcp = pkgs.callPackage ./_notify-package.nix { };

            json = (pkgs.formats.json { }).generate;

            # `mcp_tool` calls the tool directly: no shell, and no second implementation of the
            # notification to keep in step with the first. `${message}` is substituted from the hook's
            # own JSON input.
            hooks = json "hooks.json" {
                hooks.Notification = [
                    {
                        matcher = "agent_completed|agent_needs_input|idle_prompt|permission_prompt|elicitation_dialog";
                        hooks = [
                            {
                                type = "mcp_tool";
                                server = "notify";
                                tool = "notify";
                                input.message = "\${message}";
                                timeout = 5;
                            }
                        ];
                    }
                ];
            };

            manifest = json "plugin.json" {
                name = "claude-notify";
                version = "1.0.0";
                description = "Desktop notification when Claude Code wants you.";
                hooks = "./hooks/hooks.json";
            };

            # A personal plugin is how a hook is declared without touching settings.json -- the same route
            # ponytail's SessionStart hooks take (see ../_plugins).
            plugin = pkgs.runCommand "claude-notify-plugin" { } ''
                mkdir -p $out/.claude-plugin $out/hooks
                cp ${manifest} $out/.claude-plugin/plugin.json
                cp ${hooks} $out/hooks/hooks.json
            '';
        in
        {
            options.my.user.dev.ai.mcp.notify = {
                enable = tools.opt.mkDisabled "desktop notifications for the coding agents (a `notify` tool)";

                hook.enable = tools.opt.mkRiding config.my.user.dev.ai.mcp.notify.enable ''
                    Notify on Claude Code's own notifications: a turn finished, input is needed, permission
                    is being asked for.
                '';
            };

            config = lib.mkMerge [
                (lib.mkIf (mcp.enable && cfg.enable) {
                    assertions = [
                        {
                            assertion = config.my.user.dev.ai.enable;
                            message = "my.user.dev.ai.mcp.notify.enable requires my.user.dev.ai.enable";
                        }
                    ];

                    home.packages = [ notifyMcp ]; # argv mode doubles as the CLI, for testing by hand

                    programs.claude-code.mcpServers.notify.command = "${notifyMcp}/bin/notify-mcp";
                })

                (lib.mkIf (mcp.enable && cfg.hook.enable) {
                    assertions = [
                        (tools.opt.requires {
                            when = cfg.hook.enable;
                            needs = cfg.enable;
                            message = "my.user.dev.ai.mcp.notify.hook.enable requires my.user.dev.ai.mcp.notify.enable (the hook calls that server's tool)";
                        })
                    ];

                    programs.claude-code.plugins.claude-notify = plugin;
                })
            ];
        };
}
