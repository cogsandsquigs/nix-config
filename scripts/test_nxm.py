#!/usr/bin/env python3
"""Self-check for nxm's TUI and its one subprocess path. Run it: `python3
scripts/test_nxm.py`.

Covers what has no other way to fail loudly: the cursor arithmetic behind the
scrolling window (wrong by one line and the display eats the line above it), and
`run`'s three exit-code modes. No framework, no fixtures -- plain asserts.
"""

from __future__ import annotations

import contextlib
import io
import pathlib
import re
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import nxm  # noqa: E402

_strip = lambda s: re.sub(r"\033\[[0-9;]*[A-Za-z]", "", s)  # noqa: E731


def _capture(fn) -> str:
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        fn()
    return buf.getvalue()


def exit_codes() -> None:
    """`ok` decides which exit codes raise."""
    with nxm.step("exit codes"):
        head = nxm.run(["git", "rev-parse", "--abbrev-ref", "HEAD"], capture=True)
        assert head.stdout.strip(), "capture=True must return the output"
        assert nxm.run(["echo", "streamed"]).stdout == "", "streamed output is not kept"
        assert nxm.run(["false"], ok=None).returncode == 1, "ok=None accepts any code"
        assert nxm.run(["false"], ok=(0, 1)).returncode == 1, "1 is allowed here"

    try:
        with nxm.step("expected failure"):
            nxm.run(["false"])
    except subprocess.CalledProcessError as e:
        assert e.returncode == 1
    else:
        raise AssertionError("a non-ok exit code must raise")


def redraw() -> None:
    """The window erases exactly what it drew, header included."""
    nxm._TTY = True
    try:
        out = _capture(_feed_three)
        # Nothing on screen for the first line; then 1 and 2 body lines; then the
        # 3 body lines plus the header above them.
        assert [int(n) for n in re.findall(r"\033\[(\d+)A", out)] == [1, 2, 4]
        assert _strip(out).split("✓")[-1].strip() == "three lines"

        out = _capture(_fail_after_output)
        tail = _strip(out).split("✗")[-1]
        assert "last words" in tail, "output must survive a failed step"
    finally:
        nxm._TTY = sys.stdout.isatty()


def _feed_three() -> None:
    with nxm.step("three lines"):
        for i in range(3):
            nxm._feed(f"line {i}\n")


def _fail_after_output() -> None:
    with contextlib.suppress(RuntimeError):
        with nxm.step("kept on failure"):
            nxm._feed("last words\n")
            raise RuntimeError


if __name__ == "__main__":
    exit_codes()
    redraw()
    print("ok")
