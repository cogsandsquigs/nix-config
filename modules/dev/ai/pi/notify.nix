# Desktop notifications for pi, from the same package Claude Code uses (../_notify-package.nix) but by a
# different route: pi has no MCP client, so it calls the binary's argv mode as a one-shot CLI instead of
# running it as a server.
#
# One event, not two. Claude Code needs both `Notification` and `Stop` because its `Notification` never
# announces a finished turn. pi's `agent_settled` fires when it will not continue on its own, which
# covers both "done" and "wants you" -- and pi has no permission prompts, so the rest of Claude's matcher
# has no equivalent here. `turn_end` would fire mid-run too, once per turn.
#
# The extension reaches pi through `settings.extensions` rather than a file in `~/.pi/agent/extensions/`.
# pi auto-scans that directory, so a store symlink there and a settings entry would load the same
# extension twice.
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
            cfg = config.my.user.dev.ai.pi.notify;

            notifyMcp = pkgs.callPackage ../_notify-package.nix { };

            # `''${` is a Nix escape, so the braces reach the file as a JS template literal rather than
            # being interpolated here. No `import type` line: jiti runs this untyped, and naming the
            # package would be one more thing to resolve at load.
            extension = pkgs.writeText "pi-notify.ts" ''
                export default function (pi) {
                    pi.on("agent_settled", async () => {
                        await pi.exec(
                            "${notifyMcp}/bin/notify-mcp",
                            [`settled in ''${process.cwd()}`, "pi"],
                            { timeout: 5000 },
                        );
                    });
                }
            '';
        in
        {
            options.my.user.dev.ai.pi.notify.enable =
                tools.opt.mkDisabled "desktop notifications for pi (fires when the agent settles)";

            config = lib.mkIf cfg.enable {
                assertions = [
                    (tools.opt.dependsOn {
                        feature = options.my.user.dev.ai.pi.notify.enable;
                        dependency = options.my.user.dev.ai.pi.enable;
                    })
                ];

                home.packages = [ notifyMcp ]; # argv mode doubles as the CLI, for testing by hand

                programs.pi-coding-agent.settings.extensions = [ "${extension}" ];
            };
        };
}
