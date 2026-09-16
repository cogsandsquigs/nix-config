#!/usr/bin/env bash
# report.sh <state-dir>
# Render REPORT.md from state.tsv + verdicts.tsv; print its path.
# Sections: Must change (with agreed:), Accepted as-is (no-change files whose
# concern survived but was accepted), Killed or downgraded (FYI), Tally.
# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

base=$(cat "$DIR/base" 2> /dev/null || true)
repo=$(basename "$(cd "$DIR/.." && pwd)")
touch "$VERDICTS"
last=$(mktemp) # last verdict per path decides
trap 'rm -f "$last"' EXIT
awk -F'\t' '{row[$1]=$0} END{for (p in row) print row[p]}' "$VERDICTS" | sort > "$last"
{
    printf '# goodreview — %s @ %s, %s\n\n' "$repo" "${base:-whole-repo}" "$(date +%F)"
    echo '## Must change'
    awk -F'\t' '
        NR==FNR { agreed[$1]=$4; why[$1]=$5; next }
        $1=="must-change" {
            printf "- %s — %s (%s:%s; agreed: %s)\n", $2, (why[$2]!="" ? why[$2] : $4), $2, $3,
                (agreed[$2]!="" ? agreed[$2] : "both")
        }' "$last" "$STATE"
    echo
    echo '## Accepted as-is (notable)'
    awk -F'\t' '
        NR==FNR { if ($1=="no-change") nc[$2]=1; next }
        nc[$1] && $2!="killed" && $2!="downgrade" {
            printf "- %s — %s (%s, %s; agreed: %s)\n", $1, $5, $2, $3, $4 }
    ' "$STATE" "$last"
    echo
    echo '## Killed or downgraded (FYI)'
    awk -F'\t' '$2=="killed" || $2=="downgrade" {
        printf "- %s — %s (%s, %s; agreed: %s)\n", $1, $5, $2, $3, $4 }' "$last"
    echo
    echo '## Tally'
    awk -F'\t' '
        { n[$1]++; t++ }
        END { printf "%d files: %d no-change, %d must-change (%d unsure)\n",
              t, n["no-change"], n["must-change"], n["unsure"] }' "$STATE"
} > "$DIR/REPORT.md"
echo "$DIR/REPORT.md"
