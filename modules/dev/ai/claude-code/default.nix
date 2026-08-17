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

            # Each upstream pin lives in ../_sources and is named here. Two of them, and `mcp/notify.nix`
            # contributes a third plugin by writing the option directly, so a name is cheaper to read
            # than a directory scan -- and mattpocock cannot come from a claude-only scan anyway, since
            # pi reads the same fetch.
            official = import ../_sources/claude-plugins-official.nix { inherit pkgs lib; };
            mattpocock = import ../_sources/mattpocock-skills.nix { inherit pkgs; };

            payload = import ../_payload.nix;

            plugins = official // {
                mattpocock-skills = mattpocock.src;
            };

            # An attrset rather than a path, because the skills come from two directories: the shared ones
            # and the ones here that need sub-agents or an MCP server. `skills` takes one path or a table of
            # them, so the table is the only way to name both without building a derivation to merge them.
            # A name in both directories is a collision the merge would silently resolve, so it asserts.
            skillsIn =
                d: lib.mapAttrs (n: _: d + "/${n}") (lib.filterAttrs (_: t: t == "directory") (builtins.readDir d));

            shared = skillsIn payload.skills;
            own = skillsIn ./_skills;
            clashes = lib.attrNames (lib.intersectAttrs shared own);
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
                    {
                        assertion = clashes == [ ];
                        message =
                            "these skills exist both as shared and as Claude-only, so one would shadow the other: "
                            + lib.concatStringsSep ", " clashes;
                    }
                ];

                home.packages = with pkgs; [
                    claude-code
                    ccusage
                ];

                programs.claude-code = {
                    enable = true;

                    inherit (payload) context;

                    skills = shared // own;

                    # Each loads as a personal plugin at ~/.claude/skills/<name> next session. Not a
                    # marketplace: Claude auto-installs only from the trust dialog, so that route needs a
                    # manual `/plugin install` per machine. Names must not collide with the skills above.
                    inherit plugins;

                    settings = {
                        defaultMode = "acceptEdits";
                    };
                };
            };
        };
}
