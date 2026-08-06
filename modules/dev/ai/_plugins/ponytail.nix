# ponytail -- a minimalism ruleset its own SessionStart and SubagentStart hooks inject into every session
# and subagent. `/ponytail lite|full|ultra|off` retunes it at runtime, which is why no option here does.
# Its `commands/` are Codex `.toml`, so Claude reads only the skills, and its hooks run `node` -- hence
# the `nodejs` next door.
#
# The whole repo IS the plugin (marketplace entry `source: "./"`), so the fetcher output goes in whole
# rather than a subdirectory. Pinned for the reason its neighbour is: 4.8.4 plus the fixes since that tag.
{ pkgs, ... }: {
    ponytail = pkgs.fetchFromGitHub {
        owner = "DietrichGebert";
        repo = "ponytail";
        rev = "16f29800fd2681bdf24f3eb4ccffe38be3baec6b";
        hash = "sha256-Y7d4s7uqjH6IbEXhqAiQ+yaxr6iiGcv2X64LuMtG1T8=";
    };
}
