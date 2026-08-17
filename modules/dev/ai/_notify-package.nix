# The `notify` MCP server -- ./_notify-server.py, with its notification backend baked in.
#
# Shared payload rather than harness wiring, because the two harnesses reach it differently and neither
# owns it: `claude-code/mcp/notify.nix` runs it as an MCP server, and `pi/notify.nix` calls the same
# binary as a one-shot CLI, since pi has no MCP client. The argv mode below is what makes that work.
#
# Ours rather than one of the published ones (mcp-server-desktop-notify, claude-code-notify-mcp and
# friends): each is a single-author wrapper around `notify-send`/`osascript`, and this one runs in every
# session on every machine. `ps.mcp` is here already for ./_gerrit-package.nix, so writing it costs less
# than vendoring it.
{
    lib,
    stdenv,
    writers,
    python3Packages,
    libnotify,
    runCommand,
    makeWrapper,
}:
let
    # macOS takes the osascript branch instead, and osascript needs no package.
    linuxNotify = if stdenv.isLinux then "${libnotify}/bin/notify-send" else "notify-send";

    server =
        writers.writePython3Bin "notify-mcp"
            {
                libraries = [ python3Packages.mcp ];
                flakeIgnore = [ "E501" ]; # 100 columns, as everywhere else in the repo
            }
            (
                builtins.replaceStrings [ "@linuxNotify@" ] [ linuxNotify ] (builtins.readFile ./_notify-server.py)
            );
in
# A project's direnv/mise can export PYTHONPATH or PYTHONHOME at any python version it likes, and the
# server inherits the client's environment. Unset both, so the store interpreter resolves `mcp` from its
# own closure. NIX_PYTHONPATH is set after this, by the shebang.
runCommand "notify-mcp"
    {
        nativeBuildInputs = [ makeWrapper ];

        meta = {
            description = "Desktop notifications (stdio MCP server), for the coding agents";
            platforms = lib.platforms.unix;
        };
    }
    ''
        makeWrapper ${server}/bin/notify-mcp $out/bin/notify-mcp \
            --unset PYTHONPATH --unset PYTHONHOME
    ''
