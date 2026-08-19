# Claude Code. Everything under here needs something only this harness has: MCP servers, an LSP
# client, sub-agents, or the 5h usage window.
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
            cfg = config.my.user.dev.ai.claude-code;
            skills = import ../_skills { inherit pkgs lib; };
        in
        {
            options.my.user.dev.ai.claude-code.enable =
                tools.opt.mkRiding config.my.user.dev.ai.enable "Claude Code";

            config = lib.mkIf cfg.enable {
                assertions = [
                    (tools.opt.dependsOn {
                        feature = options.my.user.dev.ai.claude-code.enable;
                        dependency = options.my.user.dev.ai.enable;
                    })
                ];

                home.packages = with pkgs; [
                    claude-code
                    ccusage
                ];

                programs.claude-code = {
                    enable = true;

                    context = ../_agents.md;

                    # A single dir of skill folders; Claude symlinks it into ~/.claude/skills. A
                    # store-path string, not the derivation -- Claude's `isAttrs` check would read a
                    # derivation's attributes as skills.
                    skills = "${skills.skills.claude}";

                    settings = {
                        defaultMode = "acceptEdits";

                    };
                };
            };
        };
}
