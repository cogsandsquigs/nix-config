# MCP servers for the coding agents. One file per server, each owning its own
# `my.user.dev.ai.mcp.<name>` leaf -- all opt-in, since each talks to a private service that only
# exists on some machines.
#
# Credential defaults are `${VAR}` refs, expanded by Claude Code from its own env at launch (`.env` is
# sourced with `set -a` at shell startup) -- so they stay out of the world-readable /nix/store.
#
# Every server also rides `ai.enable` (that leaf owns programs.claude-code), so a server enabled on
# its own would emit config nothing consumes -- each file asserts against that itself.
# The group's own flag is a kill switch: it turns every server off without touching any server's own
# leaf. It deliberately does NOT ride `ai.enable`, because then disabling ai would silently drop an
# enabled server's config instead of tripping that server's assertion.
{
    home = { tools, ... }: {
        options.my.user.dev.ai.mcp.enable = tools.opt.mkEnabled "MCP servers for the coding agents";
    };
}
