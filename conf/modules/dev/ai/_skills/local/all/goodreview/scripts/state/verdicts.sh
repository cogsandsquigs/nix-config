#!/usr/bin/env bash
# verdicts.sh <state-dir>   (JSON on stdin)
# Append settlement rows: [{path, verdict, confidence, agreed, summary}].
#   verdict:    survives | killed | downgrade | escalate | unsettled
#   confidence: certain | strong | weak | uncertain
#   agreed:     agents | user | both | user-overrode-agent
# Append-only; the last row per path wins. Needs jq.
# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cat > "$tmp"
jq -e 'type=="array" and length>0 and all(.[];
    (.path|type=="string") and (.summary|type=="string") and
    (.verdict|IN("survives","killed","downgrade","escalate","unsettled")) and
    (.confidence|IN("certain","strong","weak","uncertain")) and
    (.agreed|IN("agents","user","both","user-overrode-agent")))' "$tmp" > /dev/null \
    || die 'bad verdicts JSON: [{path, verdict, confidence, agreed, summary}] (enums in header)'

jq -r '.[] | [.path, .verdict, .confidence, .agreed, .summary] | @tsv' "$tmp" >> "$VERDICTS"
