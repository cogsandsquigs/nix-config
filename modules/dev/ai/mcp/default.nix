# MCP servers for the coding agents. One file per server, each owning its own
# `my.user.dev.ai.mcp.<name>` leaf -- all opt-in, since most talk to a private service that only exists
# on some machines.
#
# Credential defaults are `${VAR}` refs, expanded by Claude Code from its own env at launch (`.env` is
# sourced with `set -a` at shell startup), so they stay out of the world-readable /nix/store.
#
# The flag here is a kill switch for the whole group. It does NOT ride `ai.enable`: each server asserts
# on that itself, and riding it would silently drop an enabled server's config instead of tripping the
# assertion.
{
    home = { tools, ... }: {
        options.my.user.dev.ai.mcp.enable = tools.opt.mkEnabled "MCP servers for the coding agents";
    };
}
