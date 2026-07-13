#!/usr/bin/env python3
"""nxm — nix manage.  Rebuild, upgrade, clean, or edit this flake.

Usage
-----
  nxm rebuild   stage all changes, rebuild the system, commit
  nxm upgrade   update flake.lock inputs then rebuild
  nxm clean     GC old nix generations
  nxm edit      open $EDITOR then rebuild

Architecture
------------
The TUI is built from three primitives, all pure stdlib:

  step(name)  — context manager. Prints "→ name" on entry, "✓/✗ name" on
                exit, and erases the rolling output block on success.

  run(cmd)    — runs a subprocess *inside* an active step, feeding its
                stdout+stderr into a 5-line circular buffer that is redrawn
                on each new line.  Raises CalledProcessError on non-zero exit.

  _feed(raw)  — internal; called by run() for each output line. Handles the
                cursor movement (ANSI escape sequences) and the buffer redraw.

Cursor mechanics (TTY only)
---------------------------
State: _buf (deque[str], maxlen=5), _shown (int — lines currently on screen).

  New line arrives:
    1. \033[{_shown}A\r\033[J  — move cursor up _shown lines, go to col 1,
                                  erase from cursor to end of screen
    2. append to _buf, reprint all _buf lines in dim grey
    3. _shown = len(_buf)

  Step succeeds:
    1. \033[{_shown+1}A\r\033[J  — same, but also erase the "→ name" header
    2. print "  ✓ name\n"

  Step fails:
    1. same erase of header + buffer
    2. print "  ✗ name\n"
    3. reprint buffer (dim grey) so the last output is still visible

When stdout is not a TTY (piped to file, CI, etc.) all cursor sequences are
skipped and each line is printed with a plain indent.

Extending
---------
To add a subcommand:
  1. Write a cmd_* function (signature: (args: argparse.Namespace) -> None).
  2. Add a sub.add_parser(...) entry in main().
  3. Add it to the dispatch dict in main().

To add a new step inside an existing command, use:
  with step("description"):
      run(["command", "arg1", "arg2"])
      run(["another", "command"])   # multiple run() calls per step are fine

run() accepts check=False to ignore a non-zero exit (useful for best-effort
commands like `git fetch` that should never abort the whole script).
"""

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
from collections.abc import Generator
from typing import Union

# ── TUI ──────────────────────────────────────────────────────────────────────

_TTY: bool = sys.stdout.isatty()

# ANSI colour/style codes — only emitted when stdout is a TTY.
_G = "\033[32m"  # green
_R = "\033[31m"  # red
_D = "\033[2m"  # dim
_W = "\033[37m"  # light grey
_B = "\033[1m"  # bold
_X = "\033[0m"  # reset all attributes

# Strip ANSI codes from subprocess output before storing in the buffer so that
# nested colour sequences don't bleed into the dim-grey rendering style.
_ANSI: re.Pattern[str] = re.compile(r"\033\[[0-9;]*[A-Za-z]")

# Rolling output buffer — last 5 lines of the current step's subprocess output.
_buf: collections.deque[str] = collections.deque(maxlen=5)
# How many output lines are currently rendered below the step header on screen.
_shown: int = 0


def _w(s: str) -> None:
    """Write directly to stdout and flush immediately."""
    sys.stdout.write(s)
    sys.stdout.flush()


def _feed(raw: str) -> None:
    """Ingest one raw output line from a subprocess into the rolling buffer.

    On a TTY: erases the previously rendered buffer lines, appends the new
    line, and redraws the whole buffer in dim grey.
    Off a TTY: plain print with an indent, no cursor movement.
    """
    global _shown
    line = _ANSI.sub("", raw.rstrip())
    if not _TTY:
        print(f"    {line}")
        return
    cols = shutil.get_terminal_size().columns
    if _shown:
        _w(f"\033[{_shown}A\r\033[J")
    _buf.append(line[: cols - 4])
    _shown = len(_buf)
    for ln in _buf:
        _w(f"  {_D}{_W}{ln}{_X}\n")


@contextlib.contextmanager
def step(name: str) -> Generator[None, None, None]:
    """Context manager for a named execution step.

    Prints "  → name" on entry.  On clean exit replaces the header+buffer with
    "  ✓ name".  On exception replaces the header with "  ✗ name" and leaves
    the buffer visible so the last lines of output remain readable.

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


def run(cmd: Union[list[str], str], check: bool = True) -> None:
    """Run a subprocess inside the current step, streaming output to the buffer.

    Args:
        cmd:   Command as a list of strings, or a whitespace-split string.
        check: If True (default), raise CalledProcessError on non-zero exit.
               Pass check=False for best-effort commands (e.g. ``git fetch``).

    stdout and stderr are merged and fed to _feed() line by line.
    Must be called inside a ``with step(...)`` block.
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


# ── Helpers ───────────────────────────────────────────────────────────────────

# Absolute path to the repo root — one level above this script's scripts/ dir.
# Works regardless of CWD or symlinks because __file__ is resolved first.
REPO: pathlib.Path = pathlib.Path(__file__).resolve().parent.parent


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
                    "c: let n = builtins.attrNames c; "
                    'in if builtins.length n == 1 then builtins.head n else ""',
                ],
                stderr=subprocess.DEVNULL,
                text=True,
            ).strip()
        except Exception:
            pass
    return target or f"{getpass.getuser()}@{socket.gethostname()}"


def _rebuild() -> None:
    """Core rebuild sequence shared by `rebuild` and `upgrade`."""
    # with step("stage"):
    #     run(["git", "fetch"], check=False)  # best-effort; offline is fine
    #     run(["git", "add", "."])

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

    # # Only commit+push when there are actually staged changes to record.
    # if subprocess.run(["git", "diff", "--cached", "--quiet"], cwd=REPO).returncode != 0:
    #     with step("commit & pull"):
    #         run(["git", "commit", "-m", "Nix rebuild"])
    #         run(["git", "pull"])

    #     with step("push"):
    #         run(["git", "push"])


def _sync_down() -> bool:
    """
    Synchronizes *down* the configuration. Adds, commits, & pulls from the repo it's in.

    Run this BEFORE calling anything else!

    Returns: Whether any synchronization changes were made.
    """

    with step("stage"):
        run(["git", "add", "."])

    did_sync = (
        subprocess.run(["git", "diff", "--cached", "--quiet"], cwd=REPO).returncode != 0
    )

    if did_sync:
        with step("stage & commit"):
            run(["git", "commit", "-m", "Nix rebuild"])

    # Regardless of commit status, pull if necessary
    if (
        subprocess.run(
            ["bash", "-c", "git fetch && git diff --quiet HEAD @{u}"],
            cwd=REPO,
        ).returncode
        != 0
    ):
        with step("pull"):
            run(["git", "pull"])

    return did_sync


def _sync_up(did_sync: bool = False) -> None:
    """
    Synchronizes *up* the configuration. If `did_sync` is true, this runs. Otherwise, does nothing.

    This is REQUIRED to be fed the output of `_sync_down`!!!

    This MUST be called last, otherwise you are at risk of pushing bad changes upstream!
    """

    if did_sync:
        with step("push"):
            run(["git", "push"])


@contextlib.contextmanager
def sync() -> Generator[None, None, None]:
    """
    Generator / context manager for a sync.

    Synchronizes down before calling any action, and then synchronizes up if necessary
    """
    try:
        did_sync = _sync_down()
        yield
    finally:
        _sync_up(did_sync)


# ── Subcommands ───────────────────────────────────────────────────────────────


def cmd_rebuild(_args: argparse.Namespace) -> None:
    """Stage all changes, rebuild the system, commit."""
    os.chdir(REPO)
    with sync():
        _rebuild()


def cmd_upgrade(_args: argparse.Namespace) -> None:
    """Update all flake inputs (flake.lock) then rebuild."""
    os.chdir(REPO)
    with sync():
        with step("update flake inputs"):
            run(["nix", "flake", "update", "--flake", str(REPO)])
        _rebuild()


def cmd_clean(_args: argparse.Namespace) -> None:
    """GC old nix generations to free disk space."""
    if sys.platform.startswith("linux") and not os.path.exists("/etc/NIXOS"):
        # Standalone home-manager (e.g. Ubuntu work desktop) — no sudo needed.
        with step("expire home-manager generations"):
            run(["home-manager", "expire-generations", "-7 days"], check=False)
        with step("nix-collect-garbage"):
            run(["nix-collect-garbage", "-d"])
    else:
        # System host (macOS / NixOS) — needs root for the system profile.
        with step("delete old generations"):
            run(["sudo", "-i", "nix-env", "--delete-generations", "old"])
        with step("nix-collect-garbage"):
            run(["sudo", "-i", "nix-collect-garbage", "-d"])


def cmd_edit(_args: argparse.Namespace) -> None:
    """Open $EDITOR interactively then rebuild."""
    editor = os.environ.get("EDITOR", "vi")
    os.chdir(REPO)
    # The editor needs raw terminal access — bypass the TUI runner entirely.
    if _TTY:
        _w(f"  {_B}→{_X} open {editor}\n")
    subprocess.run([editor], check=True)
    if _TTY:
        _w(f"  {_G}✓{_X} open {editor}\n")
    else:
        print(f"✓ open {editor}")

    with sync():
        _rebuild()


# ── Entry point ───────────────────────────────────────────────────────────────


def main() -> None:
    p = argparse.ArgumentParser(
        prog="nxm",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = p.add_subparsers(dest="cmd", required=True, metavar="COMMAND")
    sub.add_parser("rebuild", aliases=["r"], help="stage all changes, rebuild, commit")
    sub.add_parser("upgrade", aliases=["u"], help="update flake inputs then rebuild")
    sub.add_parser("clean", aliases=["c"], help="GC old nix generations")
    sub.add_parser("edit", aliases=["e"], help="open $EDITOR then rebuild")

    args = p.parse_args()
    dispatch = {
        # NOTE: each alias has to also have it's entry since argparse doesn't resolve aliases back
        # to the original parent command name. This kinda sucks.
        #
        # TODO: Force alias resolve or just find way to not have this (fragile code!)
        "rebuild": cmd_rebuild,
        "r": cmd_rebuild,
        "upgrade": cmd_upgrade,
        "u": cmd_upgrade,
        "clean": cmd_clean,
        "c": cmd_clean,
        "edit": cmd_edit,
        "e": cmd_edit,
    }
    try:
        dispatch[args.cmd](args)
    except subprocess.CalledProcessError as e:
        _w(f"\n  {_R}command failed (exit {e.returncode}){_X}\n")
        sys.exit(e.returncode)
    except KeyboardInterrupt:
        _w(f"\n  {_D}interrupted{_X}\n")
        sys.exit(130)


if __name__ == "__main__":
    main()
