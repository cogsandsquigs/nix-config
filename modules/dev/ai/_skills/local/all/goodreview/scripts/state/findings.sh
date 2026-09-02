#!/usr/bin/env bash
# findings.sh <state-dir>   (JSON on stdin)
# Ingest finder output: [{path, line, severity: high|medium|low, what, why}].
# Renders findings/<path with / -> _>.md per path (overwrites). Needs jq.
# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cat > "$tmp"
jq -e 'type=="array" and length>0 and all(.[];
    (.path|type=="string") and (.line|type=="number") and
    (.severity|IN("high","medium","low")) and
    (.what|type=="string") and (.why|type=="string"))' "$tmp" > /dev/null \
    || die 'bad findings JSON: [{path, line, severity high|medium|low, what, why}]'

mkdir -p "$DIR/findings"
jq -r '[.[].path] | unique[]' "$tmp" | while IFS= read -r p; do
    out="$DIR/findings/$(printf '%s' "$p" | tr '/' '_').md"
    {
        printf '# %s\n\n' "$p"
        jq -r --arg p "$p" \
            '.[] | select(.path==$p) | "- \(.path):\(.line) [\(.severity)] \(.what) — \(.why)"' "$tmp"
    } > "$out"
done
