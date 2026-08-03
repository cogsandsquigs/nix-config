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
            # Anthropic's managed plugin directory. A fetcher rather than a flake input, so
            # `nix flake update` cannot move third-party agent instructions underneath us -- bumping this
            # is a deliberate edit of `rev`, then the hash the build reports.
            officialPlugins = pkgs.fetchFromGitHub {
                owner = "anthropics";
                repo = "claude-plugins-official";
                rev = "892bf62a0d8d0de53025fe8b2a3d35e45cc10c55";
                hash = "sha256-U2cD8CrL54zz8wrbq4OypFCKeAPvRrS/6GbMQTjjbuc=";
            };
        in
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

                    # `_skills`, not `skills`: payload, not a namespace level, so the loader skips it
                    # rather than reading it as the feature `dev.ai.skills`.
                    skills = ./_skills;

                    # Each loads as a personal plugin at ~/.claude/skills/<name> next session. Not a
                    # marketplace: Claude auto-installs only from the trust dialog, so that route needs a
                    # manual `/plugin install` per machine. Names may not collide with ./_skills entries.
                    plugins = lib.genAttrs [ "hookify" "claude-md-management" "ralph-loop" "skill-creator" ] (
                        name: "${officialPlugins}/plugins/${name}"
                    );
                };
            };
        };
}
