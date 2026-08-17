# What every harness gets, named in one place so the two cannot drift.
#
# Not options: nothing computes these and nothing overrides them, so a declaration would be a constant
# with ceremony. The other shared things here -- `_sources/*` and `_notify-package.nix` -- are already
# reached by importing a `_` file, and this is the same job.
#
# `context` is one file rather than a directory of rules, because the two harnesses disagree on how a
# rule set is assembled and only Claude Code will concatenate one for you. Each harness renders it into
# whatever file it reads: `CLAUDE.md` for Claude Code, `AGENTS.md` for pi.
#
# `skills` holds only what works anywhere. A skill needing sub-agents or an MCP server belongs to the
# harness that has them: nothing in the SKILL.md standard lets a skill exclude itself, so an unportable
# skill shared is a skill that triggers and then finds its tools missing.
#
# One namespace caveat, for anything added to `skills`: Claude Code loads mattpocock's skills through the
# plugin channel, so they arrive scoped and cannot collide, while pi discovers them into the same flat
# namespace as these. pi warns and keeps the first it finds. Nothing collides today.
{
    context = ./_agents.md;
    skills = ./_skills;
}
