#!/usr/bin/env bash
# json.sh <state-dir>
# Dump state as JSON to stdout:
#   {base, files: [{category, path, line, summary, verdict|null}]}
# where verdict is the file's last verdicts.tsv row. Needs jq.
# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

base=$(cat "$DIR/base" 2> /dev/null || true)
touch "$VERDICTS"
state_json=$(jq -Rn \
    '[inputs | split("\t") | {category:.[0], path:.[1], line:(.[2]|tonumber? // 0), summary:.[3]}]' \
    < "$STATE")
verd_json=$(awk -F'\t' '{row[$1]=$0} END{for (p in row) print row[p]}' "$VERDICTS" \
    | jq -Rn '[inputs | split("\t") | {path:.[0], verdict:.[1], confidence:.[2], agreed:.[3], summary:.[4]}]')
jq -n --argjson files "$state_json" --argjson v "$verd_json" --arg base "$base" \
    'INDEX($v[]; .path) as $m
     | {base:$base, files: ($files | map(. + {verdict: ($m[.path] // null)}))}'
