# ponytail -- a minimalism ruleset (skip it, reuse it, stdlib, native, one line, only then write it)
# that its own SessionStart and SubagentStart hooks inject into every session and every subagent.
# Six skills come with it; `/ponytail lite|full|ultra|off` retunes or stops it at runtime, which is
# why no option here does. Its `commands/` are Codex `.toml`, so Claude reads only the skills.
#
# The whole repo IS the plugin -- its marketplace entry is `source: "./"` -- so the fetcher output
# goes in whole, not a subdirectory of it. Pinned for the reason its neighbour is. 4.8.4 plus the
# fixes since that tag; there is no newer one. The hooks run `node`, hence the `nodejs` next door.
{ pkgs, ... }: {
    ponytail = pkgs.fetchFromGitHub {
        owner = "DietrichGebert";
        repo = "ponytail";
        rev = "16f29800fd2681bdf24f3eb4ccffe38be3baec6b";
        hash = "sha256-Y7d4s7uqjH6IbEXhqAiQ+yaxr6iiGcv2X64LuMtG1T8=";
    };
}
