#!/usr/bin/env bash
#
# Bump flake.lock (update all inputs) and rebuild. Location-independent, and picks the right
# rebuild path (system vs standalone home-manager) via rebuild.sh.

set -e # exit if any command errors

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Update inputs. No sudo here: `nix flake update` only rewrites flake.lock in the repo. (System
# rebuilds still escalate inside rebuild.sh where they actually need to.)
nix flake update --flake "$FLAKE_DIR"

# Rebuild system
"$SCRIPT_DIR/rebuild.sh"
