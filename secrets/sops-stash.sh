#!/usr/bin/env bash
# Usage: sops-stash <plaintext-file> <secret-path>
# Example: sops-stash ~/profile.ovpn cogs/work-alt-ipratt-ovpn
#
# Encrypts <plaintext-file> into secrets/<secret-path>.sops using sops (binary mode).
# Must be run from anywhere in the repo; finds secrets/ automatically.
# The recipient key(s) are chosen by <secret-path> via the creation_rules in secrets/.sops.yaml.

set -euo pipefail

PLAINTEXT="${1:?usage: sops-stash <plaintext-file> <secret-path>}"
SECRET="${2:?usage: sops-stash <plaintext-file> <secret-path>}"

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
mkdir -p "$(dirname "$SECRET")"
# --filename-override makes sops pick the creation_rule by <secret-path>, even though the plaintext
# lives elsewhere. --input-type binary treats the file as raw bytes (an .ovpn, an exported key).
sops encrypt --input-type binary --output-type json \
    --filename-override "${SECRET}.sops" "$PLAINTEXT" > "${SECRET}.sops"
echo "wrote secrets/${SECRET}.sops"
