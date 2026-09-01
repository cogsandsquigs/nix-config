#!/usr/bin/env bash
# goodreview TUI — interactive triage over .goodreview/state.tsv.
#
# Usage: goodreview_tui.sh [state-dir]
#   state-dir defaults to <repo-root>/.goodreview
#
# State files (shared contract with the goodreview skill — keep in sync
# with docs/internals.md):
#   state.tsv   category<TAB>path<TAB>line<TAB>summary   (one row per file)
#   base        git ref the review diffed against (single line)
#   findings/   per-file agent findings: findings/<path with / -> __>.md
#   notes.md    user annotations, appended here as "- path:line note"
#   tui.done    written on exit so the agent knows the pass is over
set -euo pipefail

# ---------- preview mode (invoked by fzf as: $0 __preview <dir> <path> <line>)
if [ "${1:-}" = "__preview" ]; then
    dir="$2"
    path="$3"
    line="${4:-0}"
    f="$dir/findings/$(printf '%s' "$path" | tr '/' '_').md"
    if [ -f "$f" ]; then cat "$f"; else echo "(no findings recorded)"; fi
    echo
    echo "--- diff since $(cat "$dir/base" 2> /dev/null || echo '?') ---"
    if [ -s "$dir/base" ]; then
        git diff --color=always "$(cat "$dir/base")" -- "$path" 2> /dev/null | head -200
    fi
    exit 0
fi

DIR="${1:-$(git rev-parse --show-toplevel)/.goodreview}"
STATE="$DIR/state.tsv"
NOTES="$DIR/notes.md"
[ -f "$STATE" ] || {
    echo "no $STATE — run /goodreview first" >&2
    exit 1
}

set_cat() { # set_cat <category> <path>
    local tmp
    tmp=$(mktemp)
    awk -F'\t' -v OFS='\t' -v c="$1" -v p="$2" '$2==p{$1=c}1' "$STATE" > "$tmp"
    mv "$tmp" "$STATE"
}

edit_at() { # edit_at <path> <line>
    local ed="${EDITOR:-${VISUAL:-vi}}"
    if [ "${2:-0}" != "0" ] && [ -n "${2:-}" ]; then "$ed" "+$2" "$1"; else "$ed" "$1"; fi
}

note_for() { # note_for <path> <line>
    local n
    read -rp "note/question for $1:${2:-} > " n < /dev/tty
    [ -n "$n" ] && printf -- '- %s:%s %s\n' "$1" "${2:-0}" "$n" >> "$NOTES"
}

if command -v fzf > /dev/null 2>&1; then
    while true; do
        sel=$(sort "$STATE" | fzf \
            --delimiter '\t' --with-nth 1,2,4 --no-multi \
            --prompt 'goodreview> ' \
            --header $'enter=open in $EDITOR  ctrl-g=must-change  ctrl-o=no-change  ctrl-u=unsure\nctrl-a=add note/question  ctrl-d=done (hand back to Claude)' \
            --preview "bash '$0' __preview '$DIR' {2} {3}" \
            --preview-window 'right:60%:wrap' \
            --expect ctrl-a,ctrl-g,ctrl-o,ctrl-u,ctrl-d) || break
        key=$(sed -n 1p <<< "$sel")
        row=$(sed -n 2p <<< "$sel")
        [ "$key" = "ctrl-d" ] && break
        [ -z "$row" ] && continue
        path=$(cut -f2 <<< "$row")
        line=$(cut -f3 <<< "$row")
        case "$key" in
            ctrl-g) set_cat must-change "$path" ;;
            ctrl-o) set_cat no-change "$path" ;;
            ctrl-u) set_cat unsure "$path" ;;
            ctrl-a) note_for "$path" "$line" ;;
            *) edit_at "$path" "$line" ;;
        esac
    done
else
    # Fallback: no fzf — plain numbered menu, same state file.
    while true; do
        echo
        echo "goodreview (no fzf found — plain mode)"
        nl -w2 -s'. ' <(sort "$STATE" | awk -F'\t' '{printf "[%s] %s — %s\n",$1,$2,$4}')
        echo " e<N>=edit  m<N>=must-change  o<N>=no-change  u<N>=unsure  a<N>=note  q=done"
        read -rp "> " cmd < /dev/tty || break
        [ "$cmd" = q ] && break
        n="${cmd:1}"
        row=$(sort "$STATE" | sed -n "${n}p") || continue
        [ -z "${row:-}" ] && continue
        path=$(cut -f2 <<< "$row")
        line=$(cut -f3 <<< "$row")
        case "${cmd:0:1}" in
            e) edit_at "$path" "$line" ;;
            m) set_cat must-change "$path" ;;
            o) set_cat no-change "$path" ;;
            u) set_cat unsure "$path" ;;
            a) note_for "$path" "$line" ;;
        esac
    done
fi

date +%s > "$DIR/tui.done"
echo "goodreview: pass recorded. Tell Claude you're done (it also watches tui.done)."
