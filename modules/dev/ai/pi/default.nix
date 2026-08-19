# pi (earendil-works/pi), a second harness for experimentation.
#
# It gets the shared context and skills, and nothing else. pi ships no MCP client,
# no sub-agents, no plan mode and no permission prompts -- deliberate non-goals rather than gaps, so
# the claude-only features here have nothing to translate into. MCP is reachable through a third-party
# extension, but there is no first-party one and pulling an unpinned npm package at runtime buys
# nothing this box needs.
#
# `settings.skills` takes a list and discovers every directory holding a SKILL.md beneath each entry,
# so the registry's one dir is enough and individual skills need not be named. The relative
# `../.claude/skills` adds this machine's local project tooling, so pi rides the same local skill set
# claude-code does.
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
            cfg = config.my.user.dev.ai.pi;
            skills = import ../_skills { inherit pkgs lib; };
        in
        {
            options.my.user.dev.ai.pi.enable = tools.opt.mkDisabled "pi coding agent";

            config = lib.mkIf cfg.enable {
                assertions = [
                    (tools.opt.dependsOn {
                        feature = options.my.user.dev.ai.pi.enable;
                        dependency = options.my.user.dev.ai.enable;
                    })
                ];

                programs.pi-coding-agent = {
                    enable = true;

                    context = ../_agents.md;

                    extraPackages = with pkgs; [
                        python3
                        nodejs
                    ];

                    settings = {
                        defaultModel = "~deepseek/deepseek-v4-flash-latest";
                        defaultProvider = "openrouter";
                        skills = [
                            "${skills.skills.pi}"
                            "../.claude/skills" # Local project-specific claude-code skills
                        ];
                    };
                };
            };
        };
}
