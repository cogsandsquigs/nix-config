#!/usr/bin/env python3
"""Sort a feature plan's step dependency list into parallel phases.

Input is a text file of declarations, one per line:

    S3:
    S2: S3
    S5: S3
    S1: S2, S3      <- INVALID: S2 already depends on S3
    S4: S3, S5      <- INVALID: S5 already depends on S3

`S<n>: <dep>, <dep>, ...` means "S<n> depends on those steps". Every step
gets exactly one line, including steps with no dependencies. Blank lines are
ignored, as is anything after a `#`, so lines can carry a short step label.

Output is one line per phase:

    P1: S3
    P2: S2, S5
    P3: S1, S4

Steps sharing a phase are independent, so agents can implement them in
parallel. A phase depends only on the phases before it, so each completed
phase is a strictly better repository state than the one before it.

The script refuses to emit a plan it cannot vouch for. It exits 1 and prints
diagnostics to stderr when the graph has an undeclared step, a self-loop, a
cycle, or a dependency list whose members depend on each other (the last one
means the steps are not actually parallelisable, so the plan needs splitting
or the redundant edge needs dropping).

The script sees only the declared graph, never the tree: it cannot tell that
two steps' edits collide in the same file region. Edit-site disjointness
within a phase is the planner's claim and the red-team's target.
"""

import argparse
import re
import sys
from pathlib import Path

DECLARATION = re.compile(r"^(S\d+)\s*:\s*(.*)$")
STEP_NAME = re.compile(r"^S\d+$")


def step_order(name):
    """Sort key so S2 comes before S11 rather than after it."""
    return int(name[1:])


def parse(path):
    """Read a dependency file into {step: [deps]} plus a list of errors."""
    try:
        text = Path(path).read_text()
    except OSError as exc:
        return {}, [f"cannot read {path}: {exc}"]

    deps = {}
    declared_at = {}
    errors = []

    for lineno, raw in enumerate(text.splitlines(), 1):
        # `#` starts a comment anywhere on the line; step plans are usually
        # annotated with a short label per step, and rejecting those would be
        # an unhelpful surprise.
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue

        match = DECLARATION.match(line)
        if not match:
            errors.append(f"line {lineno}: expected `S<n>: ...`, got {raw.strip()!r}")
            continue

        step, rest = match.group(1), match.group(2).strip()
        if step in deps:
            errors.append(
                f"line {lineno}: {step} declared again "
                f"(first declared on line {declared_at[step]})"
            )
            continue
        declared_at[step] = lineno

        listed = [token.strip() for token in rest.split(",") if token.strip()]
        malformed = [token for token in listed if not STEP_NAME.match(token)]
        if malformed:
            errors.append(
                f"line {lineno}: {step} lists non-step tokens: {', '.join(malformed)}"
            )
            continue
        if len(set(listed)) != len(listed):
            errors.append(f"line {lineno}: {step} lists the same dependency twice")

        unique = list(dict.fromkeys(listed))
        if step in unique:
            errors.append(f"line {lineno}: {step} depends on itself")
            unique.remove(step)
        deps[step] = unique

    for step, listed in deps.items():
        for dep in listed:
            if dep not in deps:
                errors.append(f"{step} depends on {dep}, which has no declaration line")

    return deps, errors


def find_cycle(deps):
    """Return one dependency cycle as a list of steps, or None if acyclic."""
    UNVISITED, IN_PROGRESS, DONE = 0, 1, 2
    state = {step: UNVISITED for step in deps}
    stack = []

    def visit(step):
        state[step] = IN_PROGRESS
        stack.append(step)
        for dep in deps.get(step, []):
            if dep not in state:
                continue  # already reported as undeclared
            if state[dep] == IN_PROGRESS:
                return stack[stack.index(dep):] + [dep]
            if state[dep] == UNVISITED:
                found = visit(dep)
                if found:
                    return found
        stack.pop()
        state[step] = DONE
        return None

    for step in sorted(deps, key=step_order):
        if state[step] == UNVISITED:
            cycle = visit(step)
            if cycle:
                return cycle
    return None


def build_reachability(deps):
    """Map each step to the set of steps it depends on, directly or not."""
    reachable = {}

    def resolve(step):
        if step in reachable:
            return reachable[step]
        reachable[step] = set()  # guards against recursion on a cyclic graph
        acc = set()
        for dep in deps.get(step, []):
            if dep not in deps:
                continue
            acc.add(dep)
            acc |= resolve(dep)
        reachable[step] = acc
        return acc

    for step in deps:
        resolve(step)
    return reachable


def check_sibling_independence(deps, reachable):
    """Every dependency of a step must be independent of its siblings.

    Siblings run in parallel in the same phase, so if one depends on another
    they cannot. It also means the edge is redundant: the dependency is
    already implied transitively and should be dropped from the list.
    """
    errors = []
    for step in sorted(deps, key=step_order):
        listed = deps[step]
        for first in listed:
            for second in listed:
                if first == second or first not in reachable:
                    continue
                if second in reachable[first]:
                    errors.append(
                        f"{step} lists both {first} and {second}, but {first} "
                        f"already depends on {second}. Dependencies of one step "
                        f"must be independent of each other so they can be built "
                        f"in parallel. Drop `{second}` from {step}'s list, or "
                        f"split the work so they really are independent."
                    )
    return errors


def assign_phases(deps):
    """Phase number of a step is one more than its deepest dependency."""
    phase = {}

    def resolve(step):
        if step in phase:
            return phase[step]
        listed = [dep for dep in deps.get(step, []) if dep in deps]
        phase[step] = 1 if not listed else 1 + max(resolve(dep) for dep in listed)
        return phase[step]

    for step in deps:
        resolve(step)

    phases = {}
    for step, number in phase.items():
        phases.setdefault(number, []).append(step)
    return [sorted(phases[number], key=step_order) for number in sorted(phases)]


def main():
    parser = argparse.ArgumentParser(
        description="Sort feature plan step dependencies into parallel phases."
    )
    parser.add_argument("plan", help="path to the dependency file, e.g. plan-deps.txt")
    args = parser.parse_args()

    deps, errors = parse(args.plan)

    if not errors and not deps:
        errors.append(f"{args.plan} contains no step declarations")

    if not errors:
        cycle = find_cycle(deps)
        if cycle:
            errors.append("dependency cycle: " + " -> ".join(cycle))

    if not errors:
        errors.extend(check_sibling_independence(deps, build_reachability(deps)))

    if errors:
        print(f"{args.plan}: plan rejected", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    for index, steps in enumerate(assign_phases(deps), 1):
        print(f"P{index}: {', '.join(steps)}")
    return 0


if __name__ == "__main__":
    sys.setrecursionlimit(10000)
    sys.exit(main())
