{
    home =
        {
            lib,
            tools,
            config,
            pkgs,
            ...
        }:
        {
            options.my.user.dev.ai.enable =
                tools.opt.mkRiding config.my.user.dev.enable "AI tooling / coding agents (for work)";

            config = lib.mkIf config.my.user.dev.ai.enable {

                home.packages = with pkgs; [
                    # AI stuffs (work *blech*)
                    claude-code
                    ccusage
                ];

                programs.claude-code = {
                    enable = true;
                    context = ./context.md;

                    # `_skills`, not `skills`: this is payload, not a namespace level. The loader skips
                    # a `_` name, so the directory cannot be mistaken for the feature `dev.ai.skills`
                    # -- which it would have become the moment a skill shipped a `.nix` file.
                    skills = ./_skills;
                };
            };
        };
}
