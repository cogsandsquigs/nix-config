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
            # `_plugins`, like `_skills` below: payload, not a namespace level, so the loader skips it.
            # One file per upstream, each returning `<plugin directory name> -> source`, so adding a plugin
            # is a new file rather than an edit here. None declares an option -- a plugin worth switching
            # off brings its own switch.
            dir = ./_plugins;
            files = lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".nix" n) (builtins.readDir dir);
            plugins = lib.mergeAttrsList (
                lib.mapAttrsToList (n: _: import (dir + "/${n}") { inherit pkgs lib; }) files
            );
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
                    # manual `/plugin install` per machine. Names must not collide with ./_skills entries.
                    inherit plugins;

                    rulesDir = ./_rules;

                    settings = {
                        defaultMode = "acceptEdits";
                    };
                };
            };
        };
}
