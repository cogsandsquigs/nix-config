#!/usr/bin/env python3
"""nxm -- nix manage.  Rebuild, upgrade, clean, or edit this flake.

Usage
-----
  nxm rebuild        (r)   stage all changes, rebuild the system, commit
  nxm rebuild-quick  (rq)  just run the rebuild -- no git add/commit/push
  nxm upgrade        (u)   update flake.lock inputs then rebuild
  nxm clean          (c)   GC old nix generations
  nxm edit           (e)   open $EDITOR then rebuild

File layout
-----------
This file is organised top-to-bottom in the order you're most likely to
want to touch things:

  1. COMMANDS      -- one function per subcommand. Edit/add commands here.
  2. main()         -- wires the COMMANDS list up to argparse. Rarely needs touching.
  3. LIBRARY        -- the TUI (step/run/_feed) and git/nix helpers everything
                        above calls. You shouldn't need to read this to add a command.

Adding a new command
---------------------
Write a function `(args: argparse.Namespace) -> None` and put `@command(...)`
above it, e.g.::

    @command("clean", "c", "GC old nix generations")
    def cmd_clean(_args: argparse.Namespace) -> None:
        ...

That's the only place the command's name/alias/help text is declared --
no separate argparse wiring needed, main() just reads the registry.
"""

# Deferred annotations: type hints below are never evaluated at runtime, just
# stored as strings. This is what lets this file run on old Python (3.7+)
# despite using modern-looking hints like `list[str] | None` or `deque[str]`,
# which would otherwise need Python 3.9-3.10+.
from __future__ import annotations

import argparse
import collections
import contextlib
import getpass
import os
import pathlib
import re
import shutil
import socket
import subprocess
import sys
from collections.abc import Callable, Generator

# =============================================================================
# COMMANDS -- add/edit subcommands here. Nothing below this section needs
# to change when you add a new command.
# =============================================================================

# A command handler: takes the parsed argparse namespace, returns nothing.
Command = Callable[["argparse.Namespace"], None]

# Registry filled in by @command as the file is imported. main() reads this
# to build the argparse subcommands -- so name/alias/help/handler all live
# in exactly one place (the decorator line) instead of being split between
# a cmd_* function and a separate sub.add_parser(...) call.
_COMMANDS: list[tuple[str, list[str], str, Command]] = []


def command(name: str, alias: str, help: str) -> Callable[[Command], Command]:
    """Decorator: register `fn` as subcommand `name` (with short `alias`)."""

    def deco(fn: Command) -> Command:
        _COMMANDS.append((name, [alias], help, fn))
        return fn

    return deco


@command("rebuild", "r", "stage all changes, rebuild the system, commit")
def cmd_rebuild(_args: argparse.Namespace) -> None:
    os.chdir(REPO)
    with sync():
        _rebuild()


@command("rebuild-quick", "rq", "just run the rebuild -- no git add/commit/push")
def cmd_rebuild_quick(_args: argparse.Namespace) -> None:
    """Same as `rebuild` but skips _sync_down/_sync_up entirely: no staging,
    no commit, no fetch/pull, no push. For when you just want to re-apply
    the current flake without touching git."""
    os.chdir(REPO)
    _rebuild()


@command("upgrade", "u", "update flake inputs then rebuild")
def cmd_upgrade(_args: argparse.Namespace) -> None:
    os.chdir(REPO)
    with step("update flake inputs"):
        run(["nix", "flake", "update", "--flake", str(REPO)])
    with sync():
        _rebuild()


@command("clean", "c", "GC old nix generations")
def cmd_clean(_args: argparse.Namespace) -> None:
    if sys.platform.startswith("linux") and not os.path.exists("/etc/NIXOS"):
        # Standalone home-manager (e.g. Ubuntu work desktop) -- no sudo needed.
        with step("expire home-manager generations"):
            run(["home-manager", "expire-generations", "-7 days"], check=False)
        with step("nix-collect-garbage"):
            run(["nix-collect-garbage", "-d"])
    else:
        # System host (macOS / NixOS) -- needs root for the system profile.
        with step("delete old generations"):
            run(["sudo", "-i", "nix-env", "--delete-generations", "old"])
        with step("nix-collect-garbage"):
            run(["sudo", "-i", "nix-collect-garbage", "-d"])


@command("edit", "e", "open $EDITOR then rebuild")
def cmd_edit(_args: argparse.Namespace) -> None:
    editor = os.environ.get("EDITOR", "vi")
    os.chdir(REPO)
    # The editor needs raw terminal access -- bypass the TUI runner entirely.
    if _TTY:
        _w(f"  {_B}→{_X} open {editor}\n")
    subprocess.run([editor], check=True)
    if _TTY:
        _w(f"  {_G}✓{_X} open {editor}\n")
    else:
        print(f"✓ open {editor}")

    with sync():
        _rebuild()


# =============================================================================
# main() -- turns the _COMMANDS registry above into an argparse CLI.
# =============================================================================


def main() -> None:
    p = argparse.ArgumentParser(
        prog="nxm",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = p.add_subparsers(required=True, metavar="COMMAND")
    for name, aliases, help_text, fn in _COMMANDS:
        sub.add_parser(name, aliases=aliases, help=help_text).set_defaults(func=fn)

    args = p.parse_args()
    try:
        args.func(args)
    except subprocess.CalledProcessError as e:
        _w(f"\n  {_R}command failed (exit {e.returncode}){_X}\n")
        sys.exit(e.returncode)
    except KeyboardInterrupt:
        _w(f"\n  {_D}interrupted{_X}\n")
        sys.exit(130)


# =============================================================================
# LIBRARY -- TUI primitives and git/nix helpers used by the commands above.
# You shouldn't need to edit this to add or change a command.
# =============================================================================

# -- Paths ----------------------------------------------------------------

# Absolute path to the repo root -- one level above this script's scripts/ dir.
# Works regardless of CWD or symlinks because __file__ is resolved first.
REPO: pathlib.Path = pathlib.Path(__file__).resolve().parent.parent

# -- TUI --------------------------------------------------------------------
#
# The "spinner"-style output you see when running a command is built from
# three pieces:
#
#   step(name)  a `with` block. Prints "→ name" when entered, then replaces
#               that line with "✓ name" (or "✗ name" on error) when the
#               block exits.
#
#   run(cmd)    runs a subprocess *inside* a step, streaming its output into
#               a small scrolling window (last 5 lines) instead of dumping
#               everything to the terminal.
#
#   _feed(line) internal. Called once per output line by run(); does the
#               actual cursor-repositioning to redraw that scrolling window.
#
# All the "\033[...A\r\033[J" strings below are ANSI escape codes meaning
# "move cursor up N lines, then erase everything below it" -- that's how the
# window appears to update in place instead of printing a new line each time.
# When stdout isn't a real terminal (piped to a file, running in CI, etc.)
# none of that happens; it just prints plain indented lines instead.

_TTY: bool = sys.stdout.isatty()

# ANSI colour/style codes -- only meaningful when _TTY is True.
_G = "\033[32m"  # green
_R = "\033[31m"  # red
_D = "\033[2m"  # dim
_W = "\033[37m"  # light grey
_B = "\033[1m"  # bold
_X = "\033[0m"  # reset all attributes

# Strips ANSI codes from subprocess output before storing it, so a program
# that prints its own colours doesn't corrupt our dim-grey redraw.
_ANSI: re.Pattern[str] = re.compile(r"\033\[[0-9;]*[A-Za-z]")

# Rolling output buffer -- last 5 lines of the current step's subprocess output.
_buf: collections.deque[str] = collections.deque(maxlen=5)
# How many of those lines are currently drawn on screen right now.
_shown: int = 0


def _w(s: str) -> None:
    """Write directly to stdout and flush immediately (so it shows up now,
    not whenever Python next feels like flushing its buffer)."""
    sys.stdout.write(s)
    sys.stdout.flush()


def _feed(raw: str) -> None:
    """Ingest one raw output line from a subprocess into the rolling buffer.

    On a TTY: erase the previously drawn buffer lines, append the new line,
    redraw the whole buffer in dim grey.
    Off a TTY: plain print with an indent, no cursor movement.
    """
    global _shown
    line = _ANSI.sub("", raw.rstrip())
    if not _TTY:
        print(f"    {line}")
        return
    cols = shutil.get_terminal_size().columns
    if _shown:
        _w(f"\033[{_shown}A\r\033[J")  # move up _shown lines, erase to end
    _buf.append(line[: cols - 4])
    _shown = len(_buf)
    for ln in _buf:
        _w(f"  {_D}{_W}{ln}{_X}\n")


@contextlib.contextmanager
def step(name: str) -> Generator[None, None, None]:
    """Context manager for a named execution step.

    Prints "→ name" on entry. On clean exit, replaces the header + buffer
    with "✓ name". On exception, replaces the header with "✗ name" but
    leaves the buffer visible so the last lines of output are still readable.

    Example::

        with step("build"):
            run(["nix", "build"])
    """
    global _buf, _shown
    _buf = collections.deque(maxlen=5)
    _shown = 0
    if _TTY:
        _w(f"  {_B}→{_X} {name}\n")
    else:
        print(f"\n→ {name}")
    try:
        yield
    except Exception:
        if _TTY:
            _w(f"\033[{_shown + 1}A\r\033[J")
            _w(f"  {_R}✗{_X} {name}\n")
            for ln in _buf:
                _w(f"  {_D}{_W}{ln}{_X}\n")
        else:
            print(f"✗ {name}")
        raise
    else:
        if _TTY:
            _w(f"\033[{_shown + 1}A\r\033[J")
            _w(f"  {_G}✓{_X} {name}\n")
        else:
            print(f"✓ {name}")


def run(cmd: list[str] | str, check: bool = True) -> None:
    """Run a subprocess inside the current step, streaming output to the buffer.

    Args:
        cmd:   Command as a list of strings, or a whitespace-split string.
        check: If True (default), raise CalledProcessError on non-zero exit.
               Pass check=False for best-effort commands (e.g. `git fetch`).

    stdout and stderr are merged and fed to _feed() line by line.
    Must be called inside a `with step(...)` block.
    """
    if isinstance(cmd, str):
        cmd = cmd.split()
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    assert proc.stdout is not None  # guaranteed: we passed stdout=PIPE
    for line in proc.stdout:
        _feed(line)
    proc.wait()
    if check and proc.returncode != 0:
        raise subprocess.CalledProcessError(proc.returncode, cmd)


# -- git/nix helpers --------------------------------------------------------


def _hm_target() -> str:
    """Resolve the home-manager flake attribute for standalone Linux.

    Resolution order:
      1. $HM_TARGET env var (explicit override)
      2. The sole key in flake#homeConfigurations (the normal single-box case)
      3. Fallback: "<user>@<hostname>"
    """
    target = os.environ.get("HM_TARGET", "")
    if not target:
        try:
            target = subprocess.check_output(
                [
                    "nix",
                    "eval",
                    "--raw",
                    f"{REPO}#homeConfigurations",
                    "--apply",
                    (
                        "c: let n = builtins.attrNames c; "
                        'in if builtins.length n == 1 then builtins.head n else ""'
                    ),
                ],
                stderr=subprocess.DEVNULL,
                text=True,
            ).strip()
        except subprocess.TimeoutExpired:
            print("Error: `nix eval` of home configurations timed out", file=sys.stderr)
        except subprocess.CalledProcessError as e:
            print(
                f"Error: `nix eval` of home configurations returned with non-zero exit code ({e.returncode})",
                file=sys.stderr,
            )
    return target or f"{getpass.getuser()}@{socket.gethostname()}"


def _rebuild() -> None:
    """Core rebuild sequence -- picks the right tool for the current machine.
    Shared by `rebuild`, `rebuild-quick`, `upgrade`, and `edit`."""
    if sys.platform == "darwin":
        with step("darwin-rebuild switch"):
            run(
                [
                    "sudo",
                    "-i",
                    "darwin-rebuild",
                    "switch",
                    "--flake",
                    str(REPO),
                    "--print-build-logs",
                ]
            )
    elif os.path.exists("/etc/NIXOS"):
        with step("nixos-rebuild switch"):
            run(
                [
                    "sudo",
                    "-i",
                    "nixos-rebuild",
                    "switch",
                    "--flake",
                    str(REPO),
                    "--print-build-logs",
                ]
            )
    else:
        target = _hm_target()
        with step(f"home-manager switch → {target}"):
            run(
                [
                    "home-manager",
                    "switch",
                    "-b",
                    "bak",
                    "--flake",
                    f"{REPO}#{target}",
                    "--print-build-logs",
                ]
            )


def capture(
    cmd: list[str], ok: tuple[int, ...] = (0,)
) -> subprocess.CompletedProcess[str]:
    """Run cmd, capturing output, cwd=REPO. `ok` lists exit codes that are NOT
    failures (e.g. git's --quiet convention uses 0/1 as a boolean signal).
    Any other exit code feeds captured stderr/stdout into the current step's
    buffer -- same display path run() failures already use -- then raises.
    """
    proc = subprocess.run(cmd, cwd=REPO, capture_output=True, text=True, check=False)

    if proc.returncode not in ok:
        for line in (proc.stderr or proc.stdout).splitlines():
            _feed(line)
        raise subprocess.CalledProcessError(
            proc.returncode, cmd, proc.stdout, proc.stderr
        )

    return proc


def _need_pull() -> bool:
    """True iff upstream has commits we don't have (ignores local-ahead state)."""
    proc = capture(["git", "rev-list", "--count", "HEAD..@{u}"])
    return proc.stdout.strip() != "0"


def _sync_down() -> bool:
    """Synchronizes *down* the configuration: stage, commit, fetch, pull.

    Run this BEFORE calling anything else!
    Returns whether any local changes were staged/committed.
    """
    with step("stage"):
        run(["git", "add", "."])
        did_sync = (
            capture(["git", "diff", "--cached", "--quiet"], ok=(0, 1)).returncode != 0
        )

    if did_sync:
        with step("commit"):
            run(["git", "commit", "-m", "Nix rebuild"])

    with step("fetch"):
        run(["git", "fetch"], check=False)
        need_pull = _need_pull()

    if need_pull:
        with step("pull"):
            run(["git", "pull"])

    return did_sync


def _sync_up(did_sync: bool = False) -> None:
    """Synchronizes *up* the configuration: push, but only if `_sync_down`
    reported local changes. Must run last -- see `sync()` docstring."""
    if did_sync:
        with step("push"):
            run(["git", "push"])


@contextlib.contextmanager
def sync() -> Generator[None, None, None]:
    """Context manager wrapping an action in git sync-down / sync-up.

    There is deliberately no `try`: a rebuild that fails must not publish the
    commit that failed, and an exception raised in the `with` body propagates
    through the `yield`, so the push below is skipped. A `finally` here would
    push a broken tree upstream instead, and the other machine's next pull
    would then feed `darwin-rebuild` a file Nix cannot parse.
    """
    did_sync = _sync_down()
    yield
    _sync_up(did_sync)


if __name__ == "__main__":
    main()
