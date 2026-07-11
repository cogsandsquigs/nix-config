#!/usr/bin/env bash
# Usage: age-stash <plaintext-file> <secret-path>
# Example: age-stash ~/profile.ovpn cogs/work-alt-ipratt-ovpn
#
# Encrypts <plaintext-file> into secrets/<secret-path>.age using agenix.
# Must be run from anywhere in the repo; finds secrets/ automatically.
# <secret-path> must already be declared in secrets/secrets.nix.

set -euo pipefail

PLAINTEXT="${1:?usage: age-stash <plaintext-file> <secret-path>}"
SECRET="${2:?usage: age-stash <plaintext-file> <secret-path>}"

PLAINTEXT="$(realpath "$PLAINTEXT")"
[ -f "$PLAINTEXT" ] || {
    echo "error: $PLAINTEXT not found" >&2
    exit 1
}

SECRETS_DIR="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)/secrets"
[ -d "$SECRETS_DIR" ] || {
    echo "error: secrets/ not found in repo root" >&2
    exit 1
}

cd "$SECRETS_DIR"
EDITOR="cp $PLAINTEXT" agenix -e "${SECRET}.age"
echo "wrote secrets/${SECRET}.age"
