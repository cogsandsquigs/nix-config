# pi (earendil-works/pi), a second harness for experimentation.
#
# It gets the shared instructions and the portable skills, and nothing else. pi ships no MCP client,
# no sub-agents, no plan mode and no permission prompts -- deliberate non-goals rather than gaps, so
# the claude-only features here have nothing to translate into. MCP is reachable through a third-party
# extension, but there is no first-party one and pulling an unpinned npm package at runtime buys
# nothing this box needs.
#
# `settings.skills` takes a list and discovers every directory holding a SKILL.md beneath each entry,
# so bucket directories are enough and individual skills need not be named.
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

            mattpocock = import ../_sources/mattpocock-skills.nix { inherit pkgs; };
            payload = import ../_payload.nix;
        in
        {
            options.my.user.dev.ai.pi.enable = tools.opt.mkDisable "pi coding agent";

            config = lib.mkIf cfg.enable {
                assertions = [
                    (tools.opt.dependsOn {
                        feature = options.my.user.dev.ai.pi.enable;
                        dependency = options.my.user.dev.ai.enable;
                    })
                ];

                programs.pi-coding-agent = {
                    enable = true;

                    inherit (payload) context;

                    # Interpolated, not `toString`: the store copy is what pi should read, so editing a
                    # skill needs a rebuild rather than taking effect in the next session.
                    settings.skills = [ "${payload.skills}" ] ++ mattpocock.promoted;
                };
            };
        };
}
