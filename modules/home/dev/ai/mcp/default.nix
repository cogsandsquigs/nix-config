# MCP servers for the coding agents. One file per server, each owning its own
# `my.user.dev.ai.mcp.<name>` leaf — all opt-in, since each talks to a private service that only
# exists on some machines.
#
# Credential defaults are `${VAR}` refs, expanded by Claude Code from its own env at launch (`.env` is
# sourced with `set -a` at shell startup). A literal here would land in the world-readable
# /nix/store.
#
# Every server also rides `ai.enable` (that leaf owns programs.claude-code), so a server enabled on
# its own would emit config nothing consumes — each file asserts against that itself.
{
    imports = [
        ./gerrit
        ./youtrack.nix
    ];
}
