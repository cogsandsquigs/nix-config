# Coding agents. This file is the group: it installs nothing and configures no harness, it declares the
# one switch every harness rides.
#
# The split exists because a harness is a *product*, not a concept. Anything only one of them can act on
# lives under that harness -- MCP servers, language servers and the usage-window ping are all
# `claude-code/` because pi has no MCP client, no LSP client, and no 5h window.
#
# What both harnesses read is payload, not a namespace level, so the loader skips it and each harness
# imports it directly: ./_skills for the registry (the instructions, the shared skills and the pinned
# third-party sets), ./_notify-package.nix for the notifier. `_agents.md` rather than a bare `AGENTS.md`,
# so an agent working in this repo does not read it as instructions for this directory.
{
    home = { tools, config, ... }: {
        options.my.user.dev.ai.enable =
            tools.opt.mkRiding config.my.user.dev.enable "AI tooling / coding agents (for work)";
    };
}
