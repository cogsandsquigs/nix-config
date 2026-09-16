# shellcheck shell=bash
# Sourced by every scripts/state/*.sh; not executable on its own.
# Contract: the caller's $1 is the state dir; consumes it via shift.
set -euo pipefail
DIR="${1:?state dir}"
shift
STATE="$DIR/state.tsv"
# shellcheck disable=SC2034 # used by the sourcing scripts
VERDICTS="$DIR/verdicts.tsv"
[ -f "$STATE" ] || {
    echo "no $STATE — run /goodreview stage 1 first" >&2
    exit 1
}

die() {
    echo "$1" >&2
    exit 2
}
