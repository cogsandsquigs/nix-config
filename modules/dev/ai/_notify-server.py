"""Local desktop notifications, as a one-tool MCP server.

Two modes, one file: no argv runs the stdio server, argv sends one notification and exits. The
second is what the Notification hook falls back to if `mcp_tool` hooks ever stop working, and it is
how the tool is tested without a Claude Code session.

Kept to 3.8 syntax: this file is also read by whatever python a project's direnv/mise happens to
put in front of it.
"""

import subprocess
import sys

from mcp.server.fastmcp import FastMCP

# Substituted by _notify-package.nix. Linux only -- macOS takes the osascript branch below.
LINUX_NOTIFY = "@linuxNotify@"

# The text goes through argv, never through the script body: a `"` in an agent-supplied message
# would otherwise close the string and run as AppleScript.
APPLE_NOTIFY = """on run argv
    display notification (item 1 of argv) with title (item 2 of argv) sound name "Ping"
end run"""

# A freedesktop hint, so the daemon decides: GNOME plays it, mako has no sound support at all and
# drops it silently. Sound belongs to the notification either way -- nothing here spawns a player.
LINUX_SOUND = "string:sound-name:message-new-instant"


def send(message, title):
    if sys.platform == "darwin":
        cmd = ["/usr/bin/osascript", "-e", APPLE_NOTIFY, message, title]
    else:
        cmd = [LINUX_NOTIFY, "-a", title, "-h", LINUX_SOUND, "--", title, message]
    subprocess.run(cmd, check=True)


mcp = FastMCP("notify")


@mcp.tool()
def notify(message, title="Claude Code"):
    """Show a desktop notification on the user's machine.

    Use it when the user has stepped away and asked to be told something: a long job finished, a
    question is waiting, a build broke. One short line -- it is a toast, not a report.
    """
    send(message, title)
    return "notified"


if __name__ == "__main__":
    if len(sys.argv) > 1:
        send(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "Claude Code")
    else:
        mcp.run()
