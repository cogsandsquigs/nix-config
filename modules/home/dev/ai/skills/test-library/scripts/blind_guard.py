#!/usr/bin/env python3
"""PreToolUse guard for the test-library skill.

The guard enforces the blind constraint by mechanical means. It does not rely on
instructions. It reads a PreToolUse event on stdin. It exits 2 to block a read of
the audit subject that the active tier does not permit.

The state lives in three files under the temp directory.

  test-library-guard.conf   line 1 the workspace path, line 2 the tier, and one
                            optional extra closed root for each later line.
                            setup_audit.sh writes the first two lines
  test-library-guard.armed  a sentinel. The guard blocks only while this file exists
  test-library-guard.log    one line for each decision while armed. Step 7 reads it

The split into two state files matters. The setup, the dependency wiring, and the
build inside subject/ all need access to the subject, and all happen before the
explorer starts. The workflow arms the guard just before the launch of the
explorer. It disarms the guard after the contamination gate, so that the reviewer
can read the source in phase 2.

The guard protects three areas. It filters reads inside subject/ by tier. It
blocks every read inside infra/, at every tier. It applies the tier rules of the
subject to each extra closed root. An extra root exists when the install copies
the subject into project/ instead of linking it, such as an install from a packed
tarball. Without that line the copy is a full second source tree that no rule
covers.

Search tools need separate handling. A grep with no path argument searches the
working directory. A recursive search that starts above the workspace reaches the
subject without ever naming it. The guard therefore also inspects the working
directory and the pattern strings of the search tools.

The exit codes follow the hook contract. 0 allows the action. 2 blocks it and shows
the stderr message to the agent. Any unexpected condition allows the action and
prints a warning. A guard that breaks unrelated tool calls is worse than a guard
that misses one read. The manual contamination gate covers the misses, and the
decision log gives that gate something to read.
"""

import json
import os
import sys
import tempfile
from pathlib import Path

TMP = Path(os.environ.get("TMPDIR", tempfile.gettempdir()))
CONF = TMP / "test-library-guard.conf"
ARMED = TMP / "test-library-guard.armed"
LOG = TMP / "test-library-guard.log"

# The public type surface. Readable at general and lenient, not at strict.
DECLARATION_SUFFIXES = (".d.ts", ".pyi", ".h", ".hpp", ".pxd")

# Prose documentation. Readable at lenient only.
DOC_NAMES = ("readme", "readme.md", "readme.rst", "readme.txt")
DOC_DIRS = ("doc", "docs")

# Shell tools that read file contents. A bash command that joins one of these
# with a path inside a closed root is a read, whatever the tool name says.
READ_COMMANDS = (
    "cat", "less", "more", "head", "tail", "bat", "grep", "rg", "ack",
    "find", "fd", "awk", "sed", "strings", "diff", "git", "nl", "od", "xxd",
)

# The tool input keys that can hold a path.
PATH_KEYS = ("file_path", "path", "notebook_path", "filePath")

# The tool input keys that can hold a pattern. A pattern that names a closed
# directory is an attempt to search it.
PATTERN_KEYS = ("glob", "pattern")

# Tools that walk a directory tree. With no path they walk the working directory.
SEARCH_TOOLS = ("Grep", "Glob")


def log(verdict: str, tool: str, target: str) -> None:
    """Append one decision to the log. A log failure never blocks a tool call."""
    try:
        with LOG.open("a") as handle:
            handle.write(f"{verdict}\t{tool}\t{target}\n")
    except OSError:
        pass


def allow(reason=None):
    if reason:
        print(reason, file=sys.stderr)
    sys.exit(0)


def block(message):
    print(message, file=sys.stderr)
    sys.exit(2)


def load_state():
    if not ARMED.exists() or not CONF.exists():
        return None
    try:
        lines = [line.strip() for line in CONF.read_text().strip().splitlines()]
        workspace = Path(lines[0])
        tier = lines[1]
        extra = [Path(line) for line in lines[2:] if line]
        return workspace / "subject", workspace / "infra", tier, extra
    except (OSError, IndexError):
        allow("test-library guard: unreadable state file, allowing")


def permitted_at_tier(path: Path, root: Path, tier: str) -> bool:
    """Return True if this tier permits a read of this path inside a closed root."""
    if tier == "strict":
        return False

    name = path.name.lower()
    if path.name.endswith(DECLARATION_SUFFIXES):
        return True

    if tier == "lenient":
        rel_parts = [p.lower() for p in path.relative_to(root).parts]
        if name in DOC_NAMES:
            return True
        if rel_parts and rel_parts[0] in DOC_DIRS:
            return True

    return False


def candidate_paths(tool_input: dict):
    for key in PATH_KEYS:
        value = tool_input.get(key)
        if isinstance(value, str) and value:
            yield Path(value)


def resolve(path: Path):
    try:
        return path.resolve()
    except OSError:
        return None


def is_inside(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except (OSError, ValueError):
        return False


def sweeps(root_of_search: Path, closed: Path) -> bool:
    """True if a recursive search from this directory reaches the closed root.

    Both directions count. A search inside the closed root reads it. A search
    that starts above the closed root walks into it.
    """
    return is_inside(root_of_search, closed) or is_inside(closed, root_of_search)


def bash_reads_path(command: str, root: Path) -> bool:
    if str(root) not in command:
        return False
    first_words = {w.strip("'\"") for w in command.replace("|", " ").split()}
    return bool(first_words & set(READ_COMMANDS))


def main():
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        allow()

    state = load_state()
    if state is None:
        allow()
    subject, infra, tier, extra = state

    tool = str(event.get("tool_name") or "?")
    tool_input = event.get("tool_input") or {}

    # Every closed root outside infra/ follows the tier rules of the subject.
    tiered_roots = [r for r in (resolve(subject), *(resolve(p) for p in extra)) if r]
    infra_root = resolve(infra)

    # A command or a pattern carries the path as the caller wrote it, so the text
    # checks need the form from the configuration as well as the resolved form.
    infra_forms = {str(p) for p in (infra, infra_root) if p}
    tiered_forms = {str(p) for p in (subject, *extra, *tiered_roots) if p}

    subject_msg = (
        f"The test-library blind guard blocked this read. Tier '{tier}' does not "
        f"permit a read of this path inside {subject}. Use hover, completions, "
        "signature help, and the type checker instead. Record a journal entry that "
        "states what you wanted to learn. If you are the reviewer and you start "
        f"phase 2, disarm the guard first with: rm {ARMED}"
    )
    infra_msg = (
        f"The test-library blind guard blocked this read. {infra} holds provisioning "
        "detail such as schema, fixtures, and seed data. That detail would answer "
        "the milestones in advance. The brief already holds every connection "
        "coordinate that you need. If something is missing from the brief, record a "
        "journal entry that states what is missing. Do not go looking for it."
    )
    search_msg = (
        "The test-library blind guard blocked this search. The search reaches "
        f"{subject} or {infra}, which this tier closes. Name a directory inside "
        "project/ instead. A search of the subject is the read that this audit "
        "measures, so record a journal entry with the term that you wanted and the "
        "reason that you wanted it."
    )

    def refuse(message, target):
        log("block", tool, target)
        block(message)

    for path in candidate_paths(tool_input):
        resolved = resolve(path)
        if resolved is None:
            continue
        if infra_root and is_inside(resolved, infra_root):
            refuse(infra_msg, str(resolved))
        for root in tiered_roots:
            if is_inside(resolved, root) and not permitted_at_tier(resolved, root, tier):
                refuse(subject_msg, str(resolved))

    # A search tool walks a tree. Its target is the path argument, or the working
    # directory when the call gives no path.
    #
    # subject/ and infra/ block in both directions. A search inside them reads
    # them, and a search above them walks in. An extra root blocks in one
    # direction only. Extra roots live inside project/, and the explorer must
    # stay free to search its own code. The ignore files that setup_audit.sh
    # writes keep a search in project/ out of the dependency directories.
    if tool in SEARCH_TOOLS:
        given = next(candidate_paths(tool_input), None)
        origin = resolve(given) if given else resolve(Path.cwd())
        if origin:
            for closed in (infra_root, resolve(subject)):
                if closed and sweeps(origin, closed):
                    refuse(search_msg, f"{tool} tree {origin}")
            for closed in tiered_roots:
                if is_inside(origin, closed):
                    refuse(search_msg, f"{tool} tree {origin}")

        for key in PATTERN_KEYS:
            value = tool_input.get(key)
            if not isinstance(value, str) or not value:
                continue
            names = {Path(form).name for form in infra_forms | tiered_forms}
            hits = [form for form in infra_forms | tiered_forms if form in value]
            hits += [name for name in names if f"{name}/" in value]
            if hits:
                refuse(search_msg, f"{tool} pattern {value}")

    command = tool_input.get("command")
    if isinstance(command, str):
        for form in infra_forms:
            if bash_reads_path(command, Path(form)):
                refuse(infra_msg, command)
        for form in tiered_forms:
            if bash_reads_path(command, Path(form)):
                refuse(subject_msg, command)

    log("allow", tool, "-")
    allow()


if __name__ == "__main__":
    main()
