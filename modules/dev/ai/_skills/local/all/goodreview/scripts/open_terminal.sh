#!/usr/bin/env bash
# open_terminal.sh — run a command where the user can see it, best effort.
# Usage: open_terminal.sh <command> [args...]
#
# Inside zellij/tmux: a new pane split DOWN from the focused one (the user is
# already looking at that surface). Otherwise: a NEW terminal window, blocking
# until it closes — $TERM_PROGRAM's terminal preferred, then the first
# installed known one. If nothing matches, print the command and exit 3; the
# caller hands it to the user.
set -euo pipefail
[ $# -ge 1 ] || {
    echo "usage: open_terminal.sh <command> [args...]" >&2
    exit 2
}

if [ -n "${ZELLIJ:-}" ]; then
    exec zellij run --direction down --close-on-exit -- "$@"
elif [ -n "${TMUX:-}" ]; then
    exec tmux split-window -v "$(printf '%q ' "$@")"
fi

window() { # window <terminal> <command...> — new window, waits for close
    local t="$1"
    shift
    case "$t" in
        wezterm) exec wezterm start -- "$@" ;;
        kitty) exec kitty -- "$@" ;;
        gnome-terminal) exec gnome-terminal --wait -- "$@" ;;
        *) exec "$t" -e "$@" ;; # ghostty, alacritty, konsole, x-terminal-emulator
    esac
}

pref=""
case "${TERM_PROGRAM:-}" in
    ghostty) pref=ghostty ;;
    kitty) pref=kitty ;;
    WezTerm) pref=wezterm ;;
esac
for t in $pref ghostty kitty wezterm alacritty gnome-terminal konsole x-terminal-emulator; do
    if command -v "$t" > /dev/null 2>&1; then window "$t" "$@"; fi
done

# macOS without any of the above on PATH. osascript cannot wait for the
# window; the caller's tui.done watch covers the end of the pass.
cmdline=$(printf '%q ' "$@")
case "${TERM_PROGRAM:-}" in
    iTerm.app) exec osascript -e "tell application \"iTerm2\" to create window with default profile command \"$cmdline\"" ;;
    Apple_Terminal) exec osascript -e "tell application \"Terminal\" to do script \"$cmdline\"" ;;
esac

echo "goodreview: couldn't open a terminal pane or window automatically." >&2
echo "Run this yourself in another terminal:" >&2
echo "  $cmdline" >&2
exit 3
