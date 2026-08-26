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
                    package = pkgs.oh-my-pi; # Use the OMP-bin overlay pkg (see `flake.nix`, `modules/_overlays.nix`)

                    settings = {
                        setupVersion = 2; # Necessary so it doesn't ask for setup again on start
                        modelRoles.default = "openrouter/openai/gpt-5.6-luna";

                        skills.customDirectories = [
                            "${skills.skills.claude}"
                            "../.claude/skills"
                        ];

                        ## Theming ##

                        symbolPreset = "nerd";
                        theme.dark = "dark-catppuccin";
                        composer.shape = "claude";
                        statusLine = {
                            preset = "compact";
                            separator = "powerline-thin";
                            transparent = true;
                            showHookStatus = true;
                        };

                        ## Behavior ##

                        followUpMode = "all";
                        steeringMode = "all";
                        interruptMode = "wait";
                    };
                };
            };
        };
}
