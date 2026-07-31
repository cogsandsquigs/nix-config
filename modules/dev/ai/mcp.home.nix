# MCP servers for the coding agents. One file per server, each owning its own
# `my.user.dev.ai.mcp.<name>` leaf -- all opt-in, since each talks to a private service that only
# exists on some machines.
#
# Credential defaults are `${VAR}` refs, expanded by Claude Code from its own env at launch (`.env` is
# sourced with `set -a` at shell startup) -- so they stay out of the world-readable /nix/store.
#
# Every server also rides `ai.enable` (that leaf owns programs.claude-code), so a server enabled on
# its own would emit config nothing consumes -- each file asserts against that itself.
{ tools, ... }: {
    # Kill switch for the whole group -- turns every server off without touching its own leaf.
    # Deliberately NOT riding `ai.enable`: if it did, disabling ai would silently drop an enabled
    # server's config instead of tripping that server's assertion.
    options.my.user.dev.ai.mcp.enable = tools.opt.mkEnabled "MCP servers for the coding agents";
}
