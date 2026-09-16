#!/usr/bin/env bash
# goodreview TUI — guided triage over .goodreview/state.tsv.
#
# Walks the review file by file (unsure first): each screen shows one file's
# findings + diff and takes a single-key verdict.
#
# Requires: fzf, delta, bat, less (dev.ai installs them); git and coreutils
# assumed.
# No fallbacks — this is a personal tool and the environment guarantees them.
#
# Usage: goodreview_tui.sh [state-dir]
#   state-dir defaults to <repo-root>/.goodreview
#
# State files (shared contract with the goodreview skill — keep in sync
# with docs/internals.md):
#   state.tsv   category<TAB>path<TAB>line<TAB>summary   (one row per file)
#   base        git ref the review diffed against (single line)
#   findings/   per-file agent findings: findings/<path with / -> _>.md
#   notes.md    user annotations, appended here as "- path:line[-line] note"
#   tui.done    written on exit so the agent knows the pass is over
set -euo pipefail

DIR="${1:-$(git rev-parse --show-toplevel)/.goodreview}"
DIR="$(cd "$DIR" && pwd)"
STATE="$DIR/state.tsv"
NOTES="$DIR/notes.md"
[ -f "$STATE" ] || {
    echo "no $STATE — run /goodreview first" >&2
    exit 1
}
# Paths in state.tsv are repo-relative; run from the repo root regardless of
# where the spawning terminal put us.
cd "$DIR/.."

command -v fzf > /dev/null 2>&1 || {
    echo "goodreview_tui: fzf is required" >&2
    exit 1
}
BASE=""
if [ -s "$DIR/base" ]; then BASE=$(cat "$DIR/base"); fi

B=$'\e[1m' R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[36m' D0=$'\e[2m' N=$'\e[0m'

cat_color() {
    case "$1" in
        must-change) printf '%s' "$R" ;;
        no-change) printf '%s' "$G" ;;
        *) printf '%s' "$Y" ;;
    esac
}

# Review order: the work queue first, then what already has a verdict.
order() {
    awk -F'\t' '{k=($1=="unsure")?0:($1=="must-change")?1:2; print k "\t" $0}' "$STATE" \
        | sort -s -t$'\t' -k1,1n | cut -f2-
}

row_for() { awk -F'\t' -v p="$1" '$2==p' "$STATE"; }

set_cat() { # set_cat <category> <path>
    local tmp
    tmp=$(mktemp)
    awk -F'\t' -v OFS='\t' -v c="$1" -v p="$2" '$2==p{$1=c}1' "$STATE" > "$tmp"
    mv "$tmp" "$STATE"
}

# Line numbers the diff touched, one per line ("12 13 27 ..."), for markers.
changed_lines() { # changed_lines <path>
    [ -n "$BASE" ] || return 0
    git diff -U0 "$BASE" -- "$1" 2> /dev/null \
        | awk '/^@@/{split($3,a,","); n=(a[2]==""?1:a[2]); s=substr(a[1],2); for(i=0;i<n;i++) print s+i}'
}

show_file() { # show_file <cat> <path> <line> <summary> <pos> <total>
    clear
    printf '%s%s%s  %s[%s]%s  %s(%s/%s)%s\n' "$B" "$2" "$N" "$(cat_color "$1")" "$1" "$N" "$D0" "$5" "$6" "$N"
    printf '%s%s%s\n\n' "$C" "$4" "$N"
    local f
    f="$DIR/findings/$(printf '%s' "$2" | tr '/' '_').md"
    if [ -f "$f" ]; then
        bat --language=markdown --color=always --style=plain --paging=never "$f" | sed -E \
            -e "s/\[(critical|high)\]/${B}${R}[\1]${N}/Ig" \
            -e "s/\[(medium|med)\]/${Y}[\1]${N}/Ig" \
            -e "s/\[(low|info|nit)\]/${D0}[\1]${N}/Ig" \
            -e 's/^/  /'
    else
        printf '  %s(no findings recorded)%s\n' "$D0" "$N"
    fi
    echo
    if [ -n "$BASE" ]; then
        printf '%s--- diff since %s ---%s\n' "$D0" "$BASE" "$N"
        git diff "$BASE" -- "$2" 2> /dev/null | delta --paging never | head -44
    else
        printf '%s--- head of file ---%s\n' "$D0" "$N"
        head -40 "$2" 2> /dev/null || printf '%s(missing)%s\n' "$D0" "$N"
    fi
    echo
    printf '%s←h  l→%s move  %s[m]%sust-change %s[o]%sk %s[u]%snsure  %s[c]%somment lines  %s[v]%siew full diff  %s[/]%s jump  %s[d]%sone\n' \
        "$B" "$N" "$B" "$N" "$B" "$N" "$B" "$N" "$B" "$N" "$B" "$N" "$B" "$N" "$B" "$N"
}

read_key() { # one keypress; arrows come back as "left"/"right"/"up"/"down"
    local k rest
    IFS= read -rsn1 k < /dev/tty
    if [ "$k" = $'\e' ]; then
        read -rsn2 -t 0.01 rest < /dev/tty || true
        case "$rest" in
            '[C') echo right ;;
            '[D') echo left ;;
            '[A') echo up ;;
            '[B') echo down ;;
            *) echo esc ;;
        esac
    else
        echo "$k"
    fi
}

comment_on() { # comment_on <path>
    local path="$1" marks sel lines first last anchor c
    [ -f "$path" ] || return 0
    marks=$(changed_lines "$path" | tr '\n' ' ')
    sel=$(nl -ba -w4 -s'  ' "$path" | awk -v m=" $marks" \
        'BEGIN{split(m,a," "); for(i in a) ch[a[i]]=1}
       {mark=(ch[$1]==1)?"▎":" "; print mark $0}' \
        | fzf --multi --reverse --no-sort \
            --prompt "lines for $path> " \
            --header 'tab=mark line(s), enter=comment on marked, esc=cancel  (▎ = changed)') || return 0
    lines=$(awk '{sub(/^[^0-9]*/, ""); print $1+0}' <<< "$sel" | sort -n)
    first=$(head -1 <<< "$lines")
    last=$(tail -1 <<< "$lines")
    [ -n "$first" ] || return 0
    anchor=$first
    [ "$last" != "$first" ] && anchor="$first-$last"
    read -rp "comment for $path:$anchor > " c < /dev/tty
    if [ -n "$c" ]; then printf -- '- %s:%s %s\n' "$path" "$anchor" "$c" >> "$NOTES"; fi
}

pick_file() { # jump list; prints chosen path or nothing
    order | fzf --delimiter '\t' --with-nth 1,2,4 --no-multi --reverse \
        --prompt 'jump to> ' | cut -f2
}

summary() {
    clear
    printf '%sgoodreview — pass summary%s\n\n' "$B" "$N"
    awk -F'\t' '{n[$1]++} END{printf "  must-change %d\n  no-change   %d\n  unsure      %d\n", n["must-change"], n["no-change"], n["unsure"]}' "$STATE"
    echo
    awk -F'\t' '$1=="unsure"{printf "  still unsure: %s — %s\n", $2, $4}' "$STATE"
    echo
    printf '%s←/h%s back in  %s[/]%s jump  %s[d]%sone — hand back to Claude\n' "$B" "$N" "$B" "$N" "$B" "$N"
}

jump() { # set idx from the pick list, keep it on cancel
    local p i
    p=$(pick_file) || true
    if [ -n "${p:-}" ]; then
        for i in "${!FILES[@]}"; do
            if [ "${FILES[$i]}" = "$p" ]; then idx=$i; fi
        done
    fi
}

mapfile -t FILES < <(order | cut -f2)
TOTAL=${#FILES[@]}
idx=0
while true; do
    if [ "$idx" -ge "$TOTAL" ]; then
        summary
        case "$(read_key)" in
            h | left | k | up) idx=$((TOTAL - 1)) ;;
            /) jump ;;
            d | q) break ;;
        esac
        continue
    fi
    path="${FILES[$idx]}"
    IFS=$'\t' read -r cat _ line sum <<< "$(row_for "$path")"
    show_file "$cat" "$path" "$line" "$sum" "$((idx + 1))" "$TOTAL"
    case "$(read_key)" in
        m)
            set_cat must-change "$path"
            idx=$((idx + 1))
            ;;
        o)
            set_cat no-change "$path"
            idx=$((idx + 1))
            ;;
        u)
            set_cat unsure "$path"
            idx=$((idx + 1))
            ;;
        c) comment_on "$path" ;;
        v) git diff "${BASE:-HEAD}" -- "$path" 2> /dev/null | delta ;;
        l | right | j | down | "") idx=$((idx + 1)) ;;
        h | left | k | up) if [ "$idx" -gt 0 ]; then idx=$((idx - 1)); fi ;;
        /) jump ;;
        d | q) break ;;
    esac
done

date +%s > "$DIR/tui.done"
echo "goodreview: pass recorded — Claude picks it up from tui.done."
