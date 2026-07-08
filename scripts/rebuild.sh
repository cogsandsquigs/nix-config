#!/usr/bin/env bash
#
# Rebuild / switch the current machine from this flake.
#
# Works for all three host kinds, auto-detected:
#   - macOS               -> darwin-rebuild switch  (sudo)
#   - NixOS               -> nixos-rebuild switch   (sudo)
#   - other Linux (Ubuntu -> standalone home-manager switch  (no sudo)
#
# The flake dir is derived from THIS script's location, so it works whether the repo lives at
# /etc/nix (system hosts) or ~/.config/nix (the standalone work box) — no hardcoded path.
#
# NOTE: we deliberately do NOT touch $NIX_CONF_DIR. That variable controls where Nix reads
# nix.conf from (default /etc/nix), NOT where your flake lives — pointing it at the repo would
# make Nix load this repo's nix.conf, which is the macOS Determinate config and wrong on Ubuntu.

set -e # exit if any command errors

# Repo root = the parent of this script's directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$FLAKE_DIR" || exit 1

# Pull changes, and make sure all files and file changes are recognized by nix (flakes ignore
# untracked files).
git fetch || true
git add .

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ">> darwin-rebuild (macOS)"
    sudo -i darwin-rebuild switch --flake "$FLAKE_DIR" --print-build-logs
elif [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -e /etc/NIXOS ]]; then
    echo ">> nixos-rebuild (NixOS)"
    sudo -i nixos-rebuild switch --flake "$FLAKE_DIR" --print-build-logs
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Standalone home-manager (non-NixOS Linux, e.g. the Ubuntu work desktop). No sudo: this is
    # a per-user install.
    #
    # Resolve the flake attribute modularly, so renaming the box (hosts/work-desktop/id.nix)
    # needs no change here, and it does not depend on the machine's actual hostname:
    #   1. $HM_TARGET, if set — explicit override.
    #   2. else the flake's sole homeConfigurations entry (the normal single-work-box case).
    #   3. else fall back to "$(whoami)@$(hostname)".
    TARGET="${HM_TARGET:-}"
    if [[ -z "$TARGET" ]]; then
        TARGET="$(nix eval --raw "$FLAKE_DIR#homeConfigurations" \
            --apply 'c: let n = builtins.attrNames c; in if builtins.length n == 1 then builtins.head n else ""' \
            2> /dev/null || true)"
    fi
    if [[ -z "$TARGET" ]]; then
        TARGET="$(whoami)@$(hostname)"
    fi
    echo ">> home-manager switch (standalone) -> $TARGET"
    home-manager switch -b bak --flake "$FLAKE_DIR#$TARGET" --print-build-logs
else
    echo "Unsupported operating system! Can't rebuild :("
    exit 1
fi

# If all goes well, commit and push any staged changes.
if ! git diff --cached --quiet; then
    git commit -m "Nix rebuild"
    git push
fi
