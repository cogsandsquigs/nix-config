# omp (can1357/oh-my-pi), a pi fork with the IDE wired in. Opt-in; a user's home
# unit turns it on. It is compatible with every claude skill, so it rides the
# `_skills` registry's full claude set -- the same dir claude-code gets.
{
    home =
        {
            lib,
            tools,
            config,
            options,
            pkgs,
            inputs,
            ...
        }:
        let
            cfg = config.my.user.dev.ai.omp;
            skills = import ../_skills { inherit pkgs lib; };
        in
        {
            imports = [ inputs.omp.homeManagerModules.default ];

            options.my.user.dev.ai.omp.enable = tools.opt.mkDisabled "OMP coding agent (a pi fork)";

            config = lib.mkIf cfg.enable {
                assertions = [
                    (tools.opt.dependsOn {
                        feature = options.my.user.dev.ai.omp.enable;
                        dependency = options.my.user.dev.ai.enable;
                    })
                ];

                programs.omp = {
                    enable = true;

                    settings = {
                        modelRoles.default = "openrouter/~deepseek/deepseek-v4-flash-latest";
                        symbolPreset = "nerd";
                        theme.dark = "dark-catppuccin";

                        skills.customDirectories = [
                            "${skills.skills.claude}"
                            "../.claude/skills"
                        ];
                    };
                };
            };
        };
}
