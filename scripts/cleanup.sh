#!/usr/bin/env bash
#
# Garbage-collect old generations and free store space.
#
# On system hosts (macOS / NixOS) this operates on the system/root profiles, so it needs sudo.
# On a standalone home-manager box (non-NixOS Linux) there is no system profile to clean and no
# root escalation to assume — we expire the user's home-manager + profile generations instead.

set -e # exit if any command errors

if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ ! -e /etc/NIXOS ]]; then
    # Standalone home-manager (e.g. Ubuntu work desktop) — per-user, no sudo.
    home-manager expire-generations "-7 days" || true
    nix-collect-garbage -d
else
    # System host (macOS / NixOS).
    sudo -i nix-env --delete-generations old
    sudo -i nix-store --gc
    sudo -i nix-collect-garbage -d
fi
