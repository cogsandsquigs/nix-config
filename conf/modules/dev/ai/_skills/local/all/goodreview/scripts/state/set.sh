#!/usr/bin/env bash
# set.sh <state-dir> <category> <path>
# Rewrite the file's category in state.tsv (must-change | no-change | unsure).
# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

cat="${1:?category}" path="${2:?path}"
case "$cat" in
    must-change | no-change | unsure) ;;
    *) die "bad category: $cat" ;;
esac
grep -qP "^[^\t]*\t\Q$path\E\t" "$STATE" || die "not in state.tsv: $path"
tmp=$(mktemp)
awk -F'\t' -v OFS='\t' -v c="$cat" -v p="$path" '$2==p{$1=c}1' "$STATE" > "$tmp"
mv "$tmp" "$STATE"
