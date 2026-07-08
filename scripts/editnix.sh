#!/usr/bin/env bash
#
# Open the flake in $EDITOR, then rebuild. Location-independent: the repo dir is derived from
# this script's location, so it works at /etc/nix or ~/.config/nix alike.

set -e # exit if any command errors

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$FLAKE_DIR" || exit 1

$EDITOR # Open da editorrrr

git add . # Make sure nix sees all changes!

"$SCRIPT_DIR/rebuild.sh"
