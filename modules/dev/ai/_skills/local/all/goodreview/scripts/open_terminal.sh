#!/usr/bin/env bash
# open_terminal.sh — run a command in a NEW terminal window/pane, best effort.
# Usage: open_terminal.sh <command> [args...]
# Detection order: multiplexer pane (zellij/tmux) beats spawning a window,
# because the user is already looking at that surface. Then known GUI
# terminals. If nothing matches, print the command for the user to run.
set -euo pipefail
[ $# -ge 1 ] || {
    echo "usage: open_terminal.sh <command> [args...]" >&2
    exit 2
}

if [ -n "${ZELLIJ:-}" ]; then
    exec zellij run --floating -- "$@"
elif [ -n "${TMUX:-}" ]; then
    exec tmux new-window "$(printf '%q ' "$@")"
fi

cmdline=$(printf '%q ' "$@")
case "${TERM_PROGRAM:-}" in
    kitty) exec kitty @ launch --type=window -- "$@" 2> /dev/null || exec kitty -- "$@" ;;
    WezTerm) exec wezterm cli spawn --new-window -- "$@" ;;
    ghostty) command -v ghostty > /dev/null && exec ghostty -e "$@" ;;
    iTerm.app) exec osascript -e "tell application \"iTerm2\" to create window with default profile command \"$cmdline\"" ;;
    Apple_Terminal) exec osascript -e "tell application \"Terminal\" to do script \"$cmdline\"" ;;
esac

for t in kitty wezterm alacritty ghostty gnome-terminal konsole x-terminal-emulator; do
    if command -v "$t" > /dev/null 2>&1; then
        case "$t" in
            wezterm) exec wezterm start -- "$@" ;;
            gnome-terminal) exec gnome-terminal -- "$@" ;;
            konsole) exec konsole -e "$@" ;;
            *) exec "$t" -e "$@" ;;
        esac
    fi
done

echo "goodreview: couldn't open a terminal window automatically." >&2
echo "Run this yourself in another terminal:" >&2
echo "  $cmdline" >&2
exit 3
