#!/usr/bin/env python3
"""nxm -- nix manage.  Rebuild, upgrade, clean, or edit this flake.

Usage
-----
  nxm rebuild        (r)   stage all changes, rebuild the system, commit
  nxm rebuild-quick  (rq)  just run the rebuild -- no git add/commit/push
  nxm upgrade        (u)   update flake.lock inputs then rebuild
  nxm clean          (c)   GC old nix generations
  nxm edit           (e)   open $EDITOR then rebuild

File layout, top to bottom: COMMANDS (one function per subcommand), main()
(wires them to argparse), LIBRARY (the TUI and the git/nix helpers).

Adding a command is one function plus a decorator, which is the only place its
name, alias and help text are declared -- main() reads the registry::

    @command("clean", "c", "GC old nix generations")
    def cmd_clean(_args: argparse.Namespace) -> None:
        ...

Its self-check is scripts/test_nxm.py.
"""

# Deferred annotations: hints are stored as strings, never evaluated, which is what
# lets `list[str] | None` and `deque[str]` run on Python 3.7+.
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
# COMMANDS -- add/edit subcommands here. Nothing below changes when you do.
# =============================================================================

Command = Callable[["argparse.Namespace"], None]

# Filled in by @command at import; main() reads it to build the argparse subcommands.
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
            run(["home-manager", "expire-generations", "-7 days"], ok=None)
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
# =============================================================================

# The repo root: one level above this script's scripts/ dir. Correct from any CWD or
# symlink, because __file__ is resolved first.
REPO: pathlib.Path = pathlib.Path(__file__).resolve().parent.parent

# -- TUI --------------------------------------------------------------------
#
# `step(name)` is a `with` block printing "→ name", replaced by "✓ name" or "✗ name"
# when it exits. `run(cmd)` streams a subprocess into a 5-line window under that
# header, redrawn in place by `_erase`/`_body`. Off a TTY there is no cursor to move,
# so everything just prints once.

_TTY: bool = sys.stdout.isatty()

# ANSI colour/style codes -- only meaningful when _TTY is True.
_G = "\033[32m"  # green
_R = "\033[31m"  # red
_D = "\033[2m"  # dim
_W = "\033[37m"  # light grey
_B = "\033[1m"  # bold
_X = "\033[0m"  # reset all attributes

# Stripped from subprocess output, so a program printing its own colours cannot
# corrupt the dim-grey redraw.
_ANSI: re.Pattern[str] = re.compile(r"\033\[[0-9;]*[A-Za-z]")

# The window: the last 5 output lines, and how many of them are on screen. `_shown`
# counts body lines only -- the header sits one line above them.
_buf: collections.deque[str] = collections.deque(maxlen=5)
_shown: int = 0


def _w(s: str) -> None:
    """Write to stdout and flush now, rather than whenever Python next would."""
    sys.stdout.write(s)
    sys.stdout.flush()


def _erase(n: int) -> None:
    """Move the cursor up n lines and erase from there to the end of the screen.
    The one place that does cursor arithmetic; a no-op off a TTY."""
    if _TTY and n:
        _w(f"\033[{n}A\r\033[J")


def _head(color: str, glyph: str, name: str) -> None:
    """Draw a step's header line."""
    _w(f"  {color}{glyph}{_X} {name}\n") if _TTY else print(f"{glyph} {name}")


def _body() -> None:
    """Draw the buffered output lines under the current header."""
    for ln in _buf:
        _w(f"  {_D}{_W}{ln}{_X}\n")


def _feed(raw: str) -> None:
    """Ingest one raw output line from a subprocess into the rolling buffer, then
    redraw the window. Off a TTY: plain print with an indent, no redraw."""
    global _shown
    line = _ANSI.sub("", raw.rstrip())
    if not _TTY:
        print(f"    {line}")
        return
    _erase(_shown)
    _buf.append(line[: shutil.get_terminal_size().columns - 4])
    _body()
    _shown = len(_buf)


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
    global _shown
    _buf.clear()
    _shown = 0
    _head(_B, "→", name)
    try:
        yield
    except Exception:
        _erase(_shown + 1)  # the buffer, plus the header above it
        _head(_R, "✗", name)
        _body()
        raise
    else:
        _erase(_shown + 1)
        _head(_G, "✓", name)


def run(
    cmd: list[str] | str,
    ok: tuple[int, ...] | None = (0,),
    capture: bool = False,
) -> subprocess.CompletedProcess[str]:
    """Run a subprocess inside the current `with step(...)` block.

    Args:
        cmd:     Command as a list of strings, or a whitespace-split string.
        ok:      Exit codes that are NOT failures. `None` accepts any, for a
                 best-effort command (e.g. `git fetch`). A non-default tuple is
                 for git's --quiet convention, where 0/1 is a boolean signal.
        capture: Hold the output and return it in `.stdout` rather than streaming
                 it into the step's window. Streamed output is not retained, so
                 `.stdout` is empty unless this is set.

    Failing output reaches the window either way, so an error looks the same
    whichever mode produced it.
    """
    if isinstance(cmd, str):
        cmd = cmd.split()

    if capture:
        proc = subprocess.run(
            cmd, cwd=REPO, capture_output=True, text=True, check=False
        )
        if ok is not None and proc.returncode not in ok:
            for line in (proc.stderr or proc.stdout).splitlines():
                _feed(line)
    else:
        popen = subprocess.Popen(
            cmd,
            cwd=REPO,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
        assert popen.stdout is not None  # guaranteed: we passed stdout=PIPE
        for line in popen.stdout:
            _feed(line)
        proc = subprocess.CompletedProcess(cmd, popen.wait(), "", "")

    if ok is not None and proc.returncode not in ok:
        raise subprocess.CalledProcessError(
            proc.returncode, cmd, proc.stdout, proc.stderr
        )
    return proc


# -- git/nix helpers --------------------------------------------------------


def _hm_target() -> str:
    """The home-manager flake attribute for this machine: $HM_TARGET, else
    "<user>@<hostname>".

    tools/default.nix keys home configurations "<primaryUser>@<host directory>", so
    the fallback reconstructs the key rather than looking it up. It misses only where
    the OS reports a different hostname than the directory (an FQDN, a `.local`
    suffix), and home-manager then fails naming the attribute it could not find --
    which is what $HM_TARGET is for.
    """
    return os.environ.get("HM_TARGET") or f"{getpass.getuser()}@{socket.gethostname()}"


def _rebuild() -> None:
    """Core rebuild sequence -- picks the right tool for the current machine.
    Shared by `rebuild`, `rebuild-quick`, `upgrade`, and `edit`.

    A new machine class is one more branch naming its step and its argv; the
    `--print-build-logs` and the `with step(...)` around them are shared."""
    if sys.platform == "darwin":
        name = "darwin-rebuild switch"
        argv = ["sudo", "-i", "darwin-rebuild", "switch", "--flake", str(REPO)]
    elif os.path.exists("/etc/NIXOS"):
        name = "nixos-rebuild switch"
        argv = ["sudo", "-i", "nixos-rebuild", "switch", "--flake", str(REPO)]
    else:
        # Standalone home-manager: per-user Nix, no system layer, so the flake ref
        # carries the "<user>@<host>" attribute rather than the bare repo.
        target = _hm_target()
        name = f"home-manager switch → {target}"
        argv = ["home-manager", "switch", "-b", "bak", "--flake", f"{REPO}#{target}"]

    with step(name):
        run(argv + ["--print-build-logs"])


def _need_pull() -> bool:
    """True iff upstream has commits we don't have (ignores local-ahead state)."""
    proc = run(["git", "rev-list", "--count", "HEAD..@{u}"], capture=True)
    return proc.stdout.strip() != "0"


def _sync_down() -> bool:
    """Synchronizes *down* the configuration: stage, commit, fetch, pull.

    Run this BEFORE calling anything else!
    Returns whether any local changes were staged/committed.
    """
    with step("stage"):
        run(["git", "add", "."])
        staged = run(["git", "diff", "--cached", "--quiet"], ok=(0, 1), capture=True)
        did_sync = staged.returncode != 0

    if did_sync:
        with step("commit"):
            run(["git", "commit", "-m", "Nix rebuild"])

    with step("fetch"):
        run(["git", "fetch"], ok=None)
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
    """Wrap an action in git sync-down / sync-up.

    Deliberately no `try`: an exception in the body propagates through the `yield`
    and skips the push, so a failed rebuild never publishes its commit. A `finally`
    would push the broken tree, and the next machine to pull would hand
    `darwin-rebuild` a file Nix cannot parse.
    """
    did_sync = _sync_down()
    yield
    _sync_up(did_sync)


if __name__ == "__main__":
    main()
