#!/usr/bin/env bash
#
# Mint FRESH per-machine GPG subkeys (signing + encryption) from your offline master, and stash them
# as that machine's agenix secret. A distinct subkey set per box means you can revoke one machine
# without touching the others.
#
# ⚠ RUN ON YOUR AIR-GAPPED / OFFLINE BOX. Adding subkeys needs the master SECRET; this imports it
#   into a throwaway keyring that's wiped on exit — but on an online machine that briefly writes the
#   master to local disk, defeating the point of keeping it offline. Do this where the master lives.
#
# ⚠ Per-machine ENCRYPTION subkeys: content encrypted to one machine's [E] subkey only decrypts on
#   that machine (senders pick one subkey). If you'd rather read encrypted mail/files on every box,
#   share ONE [E] subkey instead (drop the `cv25519 encr` line). Per-machine [S] is the part that
#   actually buys revocation/isolation.
#
# Prereqs (in the repo checkout you run this from):
#   • the target machine's age key bootstrapped + its "cogs@<host>" line in secrets/recipients.nix
#   • "cogs@<host>/gpg" added to the `declared` list in secrets/secrets.nix
#
# Usage:  ./mint-machine-subkeys.sh <master-secret.asc> <host> [expire]
#   <master-secret.asc>  armored master secret key from your offline backup
#   <host>               the machine identity's host (e.g. home-desktop) → secret cogs@<host>/gpg
#   [expire]             gpg expire spec; default 0 (never)
set -euo pipefail

MASTER_ASC="${1:?path to master-secret.asc}"
HOST="${2:?host, e.g. home-desktop}"
EXPIRE="${3:-0}" # 0 = never
NAME="cogs@${HOST}/gpg"
DIR="$(cd "$(dirname "$0")" && pwd)" # this secrets/ dir (agenix rules live here)

# Best-effort secure wipe (shred on Linux, rm -P on macOS, else plain rm).
wipe() {
    [ -n "${1:-}" ] || return 0
    shred -u "$1" 2> /dev/null || rm -P "$1" 2> /dev/null || rm -f "$1"
}

# Throwaway keyring so we never touch your real ~/.gnupg.
GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
chmod 700 "$GNUPGHOME"
KEYTMP=""
cleanup() {
    wipe "$KEYTMP"
    gpgconf --kill gpg-agent 2> /dev/null || true
    rm -rf "$GNUPGHOME"
}
trap cleanup EXIT

gpg --batch --import "$MASTER_ASC"
FPR="$(gpg --list-secret-keys --with-colons | awk -F: '/^fpr:/{print $10; exit}')"
echo ">> master $FPR"

subs() { gpg --list-keys --with-colons "$FPR" | awk -F: '/^sub:/{print $5}' | sort; }
before="$(subs)"

echo ">> adding signing (ed25519) + encryption (cv25519) subkeys, expire=$EXPIRE"
gpg --quick-add-key "$FPR" ed25519 sign "$EXPIRE" # prompts for the master passphrase
gpg --quick-add-key "$FPR" cv25519 encr "$EXPIRE"

# The new subkeys are whatever `before` didn't have (portable: no mapfile — works on bash 3.2).
# shellcheck disable=SC2046  # word-splitting is intentional: two hex subkey ids → $1 $2
set -- $(comm -13 <(echo "$before") <(subs))
[ "$#" -eq 2 ] || {
    echo "!! expected 2 new subkeys, got $#: $*" >&2
    exit 1
}
echo ">> new subkeys: $1 (sign), $2 (encr)"

KEYTMP="$(mktemp)"
gpg --armor --export-secret-subkeys "${1}!" "${2}!" > "$KEYTMP" # ONLY the new subkeys; master = stub
mkdir -p "$DIR/cogs@${HOST}"
(cd "$DIR" && EDITOR="cp $KEYTMP" agenix -e "${NAME}.age")
echo ">> wrote secrets/${NAME}.age (encrypted to cogs@${HOST})"

echo ""
echo ">> Re-publish your UPDATED master public key so the new subkeys are recognised elsewhere"
echo "   (this temp keyring only knows subkeys from the backup + these two — see the pubkey caveat):"
gpg --armor --export "$FPR"
