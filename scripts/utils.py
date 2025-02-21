"""
Utilities to update and upgrade the Nix configuration.
"""

from os import path
from platform import system
from subprocess import run

NIX_FLAKE_PATH = path.dirname(path.dirname(__file__))  # Gets nix flake location


def update(stdout, stderr):
    """
    Updates the system's Nix configuration.
    Internally, it calls `nix flake update --flake $NIX_FLAKE_PATH`, where $NIX_FLAKE_PATH is the
    path to the directory containing the flake.nix file (w.r.t this file's folder, its `./..`).
    """

    run(
        ["nix", "flake", "update", "--flake", NIX_FLAKE_PATH],
        stdout=stdout,
        stderr=stderr,
        capture_output=True,
        check=True,
    )


# TODO: Emulate this cmd:
# # rebuild, output simplified errors, log trackebacks
# darwin-rebuild switch --flake /etc/nix &>darwin-switch.log || (cat darwin-switch.log | grep --color error && exit 1) # todo: dynamic based on os


def rebuild(stdout, stderr):
    """
    Rebuilds the system's Nix configuration.
    Internally, it calls `$REBUILD_CMD switch --flake $NIX_FLAKE_PATH`, where $NIX_FLAKE_PATH is the
    path to the directory containing the flake.nix file (w.r.t this file's folder, its `./..`).
    $REBUILD_CMD is different depending on the system, and is either `darwin-rebuild` or
    `nixos-rebuild`.
    """

    match system():
        case "MacOS" | "Darwin":
            REBUILD_CMD = "darwin-rebuild"
        case _:
            REBUILD_CMD = "nixos-rebuild"  # Default to NixOS

    run(
        [REBUILD_CMD, "switch", "--flake", NIX_FLAKE_PATH],
        stdout=stdout,
        stderr=stderr,
        capture_output=False,
        check=True,
    )


rebuild(None, None)
