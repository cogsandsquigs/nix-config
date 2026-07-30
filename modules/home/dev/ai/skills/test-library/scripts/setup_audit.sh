#!/usr/bin/env bash
#
# Scaffold a blind-audit workspace for the test-library skill.
#
#   setup_audit.sh <subject-path> <mode> <tier> [workspace]
#
#     subject-path  the library or module directory to audit
#     mode          library | module
#     tier          strict | general | lenient
#     workspace     optional. The default is $TMPDIR/<name>-audit
#
# The script copies the subject exactly, minus the exclusions below. It records
# the source commit. It writes a findings.md skeleton with the setup block
# filled in.
#
# Exclusions, and the reason for each one:
#   .git            the git history is closed to the explorer at every tier.
#                   findings.md records the commit hash instead
#   node_modules    the manifest installs it again. A copy is slow and useless
#   target          the Rust build cache. The build makes it again
#   .venv           the Python virtualenv. The build makes it again
#   __pycache__     stale bytecode
#   .pytest_cache   a test cache. In module mode it also leaks information
#
# The script keeps the build output that ships to consumers, such as dist/,
# lib/, and pkg/. The explorer needs the same artifacts that a real consumer
# resolves.

set -euo pipefail

die() { printf 'error: %s\n' "$1" >&2; exit 1; }

usage() {
    sed -n '3,10p' "$0" | sed 's/^# \?//'
    exit 2
}

[ "$#" -ge 3 ] || usage

SUBJECT_PATH="$1"
MODE="$2"
TIER="$3"

[ -d "$SUBJECT_PATH" ] || die "subject path is not a directory: $SUBJECT_PATH"

case "$MODE" in
    library|module) ;;
    *) die "mode must be 'library' or 'module', got: $MODE" ;;
esac

case "$TIER" in
    strict|general|lenient) ;;
    *) die "tier must be 'strict', 'general' or 'lenient', got: $TIER" ;;
esac

SUBJECT_PATH="$(cd "$SUBJECT_PATH" && pwd)"
SUBJECT_NAME="$(basename "$SUBJECT_PATH")"
WORKSPACE="${4:-${TMPDIR:-/tmp}/${SUBJECT_NAME}-audit}"
WORKSPACE="${WORKSPACE%/}"

if [ -e "$WORKSPACE" ] && [ -n "$(ls -A "$WORKSPACE" 2>/dev/null)" ]; then
    die "workspace exists and is not empty: $WORKSPACE
       Remove it, or pass a different path. A reused workspace can mix the
       journals of two runs. Nobody can then read the report."
fi

# The commit hash is metadata only. A subject outside a repository still works.
if COMMIT="$(git -C "$SUBJECT_PATH" rev-parse --short HEAD 2>/dev/null)"; then
    if ! git -C "$SUBJECT_PATH" diff --quiet HEAD 2>/dev/null; then
        COMMIT="$COMMIT (dirty working tree)"
    fi
else
    COMMIT="unknown (not a git repository)"
fi

# infra/ holds compose files, env files and seed scripts. The blind guard blocks
# every read inside it, at every tier. Provisioning detail cannot reach the explorer.
mkdir -p "$WORKSPACE/project" "$WORKSPACE/infra"

EXCLUDES=(.git node_modules target .venv __pycache__ .pytest_cache)

if command -v rsync >/dev/null 2>&1; then
    RSYNC_ARGS=()
    for e in "${EXCLUDES[@]}"; do RSYNC_ARGS+=(--exclude "$e"); done
    rsync -a "${RSYNC_ARGS[@]}" "$SUBJECT_PATH/" "$WORKSPACE/subject/"
else
    # Without rsync, copy everything and then prune. Slower, same result.
    cp -R "$SUBJECT_PATH" "$WORKSPACE/subject"
    for e in "${EXCLUDES[@]}"; do
        find "$WORKSPACE/subject" -name "$e" -prune -exec rm -rf {} + 2>/dev/null || true
    done
fi

: > "$WORKSPACE/journal.md"

# A dependency directory inside project/ can hold a copy of the subject, and a
# recursive search would walk into it. Search tools honor these files, so a search
# of project/ stays on the code of the explorer. The guard closes the copy as well
# when the configuration names it.
IGNORE="node_modules/
site-packages/
vendor/
target/
.venv/
dist/"
printf '%s\n' "$IGNORE" > "$WORKSPACE/project/.gitignore"
cp "$WORKSPACE/project/.gitignore" "$WORKSPACE/project/.rgignore"

# Configuration for scripts/blind_guard.py. The script writes it disarmed. The
# build inside subject/ and the wiring of project/ both need access to the
# subject, and both happen before the explorer starts. The workflow arms the
# guard just before the launch.
#
# Line 1 is the workspace and line 2 is the tier. Each later line adds one closed
# root that follows the same tier rules as subject/. Add a line when the install
# copies the subject into project/ instead of linking it, such as an install from
# a packed tarball:
#
#   echo "$WORKSPACE/project/node_modules/<package>" >> "$GUARD_CONF"
GUARD_CONF="${TMPDIR:-/tmp}/test-library-guard.conf"
GUARD_LOG="${TMPDIR:-/tmp}/test-library-guard.log"
printf '%s\n%s\n' "$WORKSPACE" "$TIER" > "$GUARD_CONF"
rm -f "${TMPDIR:-/tmp}/test-library-guard.armed"
: > "$GUARD_LOG"

cat > "$WORKSPACE/findings.md" <<EOF
# \`$SUBJECT_NAME\` — blind usability audit

**Setup**
- Subject: $SUBJECT_NAME
- Mode: $MODE
- Source commit: $COMMIT
- Audit workspace: $WORKSPACE
- Information tier: $TIER
- Consumed as: (fill in: path dep / packed tarball / workspace alias)
- Blind constraint held: (fill in after the contamination gate)
- Language server available: (fill in; if not, note that strict collapses to general)
EOF

cat <<EOF
Workspace ready: $WORKSPACE
  subject/   verbatim copy at $COMMIT — off-limits to the explorer per tier '$TIER'
  project/   empty; wire it to subject/ the way a real consumer would
  infra/     empty; put compose files, env and seed scripts here, never in project/
  journal.md empty; the explorer appends to it
  findings.md setup block prefilled

Guard config written to $GUARD_CONF, currently DISARMED.
Guard decision log: $GUARD_LOG — the contamination gate in step 7 reads it.

If the install copies the subject into project/ rather than linking it, close that
copy too:
  echo "$WORKSPACE/project/node_modules/<package>" >> $GUARD_CONF

Next: build inside subject/ if it ships compiled artifacts, wire up project/,
provision any resources the milestones need into infra/ and verify they are
reachable, fill brief.md from references/explorer-brief.md, run the leakage gate,
then arm the guard with: touch ${TMPDIR:-/tmp}/test-library-guard.armed
EOF
