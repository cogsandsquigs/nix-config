#!/usr/bin/env bash
# goodreview mechanical census. Read-only. Prints a markdown table.
#
# Covers the countable half of Phase 0 and Phase 2. It does not run the build,
# the tests, or the linter, because those commands are project-specific. Fill
# those three rows in by hand.
#
# Usage: scan.sh [path]   (default: current directory)
#
# Every tool below is optional. A missing tool prints "n/a" rather than failing,
# so the script gives a partial census instead of no census.

set -u
ROOT="${1:-.}"
cd "$ROOT" || {
    echo "cannot enter $ROOT"
    exit 1
}

# Thresholds match the ones the skill uses when it classifies findings.
# 500 lines: a file with two reasons to change. 50 lines: a function that
# probably mixes a decision with input and output.
FILE_LINES=500
FUNC_LINES=50

have() { command -v "$1" > /dev/null 2>&1; }

# Prefer ripgrep. Fall back to grep -r, which is slower and noisier but present
# on every system.
if have rg; then
    SEARCH() { rg --no-messages -c "$1" . 2> /dev/null | awk -F: '{s+=$NF} END {print s+0}'; }
    SEARCHI() { rg --no-messages -ci "$1" . 2> /dev/null | awk -F: '{s+=$NF} END {print s+0}'; }
else
    SEARCH() { grep -rEc "$1" . 2> /dev/null | awk -F: '{s+=$NF} END {print s+0}'; }
    SEARCHI() { grep -rEci "$1" . 2> /dev/null | awk -F: '{s+=$NF} END {print s+0}'; }
fi

# Track only files git tracks. That skips vendored code, build output, and
# anything ignored, with no per-language exclude list to maintain.
if git rev-parse --git-dir > /dev/null 2>&1; then
    FILES_CMD() { git ls-files; }
    COMMIT=$(git rev-parse --short HEAD 2> /dev/null || echo "unknown")
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2> /dev/null || echo "unknown")
else
    FILES_CMD() { find . -type f -not -path './.git/*'; }
    COMMIT="not a git repository"
    BRANCH="n/a"
fi

FILES=$(FILES_CMD | wc -l | tr -d ' ')
LINES=$(FILES_CMD | tr '\n' '\0' | xargs -0 wc -l 2> /dev/null | tail -1 | awk '{print $1}')
BIGGEST=$(FILES_CMD | tr '\n' '\0' | xargs -0 wc -l 2> /dev/null \
    | sort -rn | awk 'NR>1 && $2!="total" {print $2" ("$1" lines)"; exit}')
OVER_FILE=$(FILES_CMD | tr '\n' '\0' | xargs -0 wc -l 2> /dev/null \
    | awk -v n="$FILE_LINES" '$2!="total" && $1>n' | wc -l | tr -d ' ')

HATCH=$(SEARCH 'ts-ignore|ts-expect-error|ts-nocheck|eslint-disable|type:[[:space:]]*ignore|noqa|nolint|SuppressWarnings|#\[allow|HLINT ignore|-Wno-|as any|as unknown as|\bcast\(|\.unwrap\(\)|unsafeCoerce|interface\{\}')
SWALLOW=$(SEARCH 'catch[[:space:]]*\([^)]*\)[[:space:]]*\{[[:space:]]*\}|except:[[:space:]]*$|except Exception:[[:space:]]*pass|_[[:space:]]*=[[:space:]]*err')
MARKER=$(SEARCH 'TODO|FIXME|HACK|XXX')
EXCUSE=$(SEARCHI 'simplest (approach|solution|way)|for now|workaround|temporar')

CYCLES="n/a"
if have madge; then CYCLES=$(madge --circular . 2> /dev/null | grep -c '^[0-9]'); fi

DEPS="n/a"
if have knip; then
    DEPS=$(knip --reporter compact 2> /dev/null | grep -ci 'unused dependenc')
elif have deptry; then
    DEPS=$(deptry . 2> /dev/null | grep -c 'DEP002')
elif [ -f go.mod ] && have go; then
    DEPS="run: go mod tidy"
fi

cat << EOF
## Provenance
Commit: $COMMIT. Branch: $BRANCH. Scope: $(pwd)

## Baseline
| Metric | Before | After |
|---|---|---|
| Build result and warnings | fill in by hand | |
| Tests pass, fail, skip | fill in by hand | |
| Lint errors and warnings | fill in by hand | |
| Type-checker errors | fill in by hand | |
| Source files | $FILES | |
| Total source lines | ${LINES:-0} | |
| Largest file, with its path | ${BIGGEST:-n/a} | |
| Files over $FILE_LINES lines | $OVER_FILE | |
| Escape hatches | $HATCH | |
| Swallowed errors | $SWALLOW | |
| Marker comments | $MARKER | |
| Shortcut excuses in comments | $EXCUSE | |
| Import cycles | $CYCLES | |
| Unused dependencies | $DEPS | |

Functions over $FUNC_LINES lines: count with the language tool in
references/scans.md. No portable one-liner gives a correct count.
EOF
