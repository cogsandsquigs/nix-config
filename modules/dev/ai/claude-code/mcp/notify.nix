# Desktop notifications: a `notify` tool the agent can call, packaged in ../../_notify-package.nix, plus
# the Claude Code hooks calling that same tool when a turn ends or Claude wants you. pi reaches the same
# package through ../../pi/notify.nix, by a different route.
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
            options,
            pkgs,
            ...
        }:
        let
            mcp = config.my.user.dev.ai.claude-code.mcp;
            cfg = mcp.notify;

            notifyMcp = pkgs.callPackage ../../_notify-package.nix { };

            json = (pkgs.formats.json { }).generate;

            # `mcp_tool` calls the tool directly: no shell, and no second implementation of the
            # notification to keep in step with the first. `${message}` is substituted from the hook's
            # own JSON input.
            #
            # `plugin:hm:notify`, not `notify`: home-manager ships every server in `mcpServers` through a
            # plugin of its own named `hm` (~/.claude/skills/claude-code-home-manager), and a
            # plugin-provided server is addressed by its scoped name. The bare key resolves to nothing,
            # silently. Claude Code exposes the tool as `mcp__plugin_hm_notify__notify`, which is where
            # to read the current scope if home-manager ever renames that plugin.
            call = message: [
                {
                    type = "mcp_tool";
                    server = "plugin:hm:notify";
                    tool = "notify";
                    input.message = message;
                    timeout = 5;
                }
            ];

            # Two events, because `Notification` alone never announces a finished turn: it fires when
            # Claude Code decides to notify, and an ordinary turn ending is not one of those moments.
            # `Stop` is the unconditional one. Its `cwd` is what tells two sessions apart.
            hooks = json "hooks.json" {
                hooks = {
                    Notification = [
                        {
                            matcher = "agent_needs_input|idle_prompt|permission_prompt|elicitation_dialog";
                            hooks = call "\${message}";
                        }
                    ];

                    Stop = [ { hooks = call "finished in \${cwd}"; } ];
                };
            };

            manifest = json "plugin.json" {
                name = "claude-notify";
                version = "1.0.0";
                description = "Desktop notification when Claude Code wants you.";
                hooks = "./hooks/hooks.json";
            };

            # A personal plugin is how a hook is declared without touching settings.json.
            plugin = pkgs.runCommand "claude-notify-plugin" { } ''
                mkdir -p $out/.claude-plugin $out/hooks
                cp ${manifest} $out/.claude-plugin/plugin.json
                cp ${hooks} $out/hooks/hooks.json
            '';
        in
        {
            options.my.user.dev.ai.claude-code.mcp.notify = {
                enable = tools.opt.mkDisabled "desktop notifications for Claude Code (a `notify` tool)";

                hook.enable = tools.opt.mkRiding config.my.user.dev.ai.claude-code.mcp.notify.enable ''
                    Notify on Claude Code's own notifications: a turn finished, input is needed, permission
                    is being asked for.
                '';
            };

            config = lib.mkMerge [
                (lib.mkIf (mcp.enable && cfg.enable) {
                    assertions = [
                        (tools.opt.dependsOn {
                            feature = options.my.user.dev.ai.claude-code.mcp.notify.enable;
                            dependency = options.my.user.dev.ai.claude-code.enable;
                        })
                    ];

                    home.packages = [ notifyMcp ]; # argv mode doubles as the CLI, for testing by hand

                    programs.claude-code.mcpServers.notify.command = "${notifyMcp}/bin/notify-mcp";
                })

                (lib.mkIf (mcp.enable && cfg.hook.enable) {
                    assertions = [
                        (tools.opt.dependsOn {
                            feature = options.my.user.dev.ai.claude-code.mcp.notify.hook.enable;
                            dependency = options.my.user.dev.ai.claude-code.mcp.notify.enable;
                            because = "the hook calls that server's tool";
                        })
                    ];

                    programs.claude-code.plugins.claude-notify = plugin;
                })
            ];
        };
}
