"""
Utilities to update and upgrade the Nix configuration.
"""

import subprocess
import sys
from os import environ, path
from platform import system

NIX_FLAKE_PATH = path.dirname(path.dirname(__file__))  # Gets nix flake location


def update():
    """
    Upgrades the system's Nix configuration.
    Internally, it calls `nix flake update --flake $NIX_FLAKE_PATH`, where $NIX_FLAKE_PATH is the
    path to the directory containing the flake.nix file (w.r.t this file's folder, its `./..`).
    """

    return invoke_process_popen_poll_live(
        ["nix", "flake", "update", "--verbose", "--flake", NIX_FLAKE_PATH],
        "🔼 Updating Flake lockfile",
    )


# TODO: Emulate this cmd:
# # rebuild, output simplified errors, log trackebacks
# darwin-rebuild switch --flake /etc/nix &>darwin-switch.log || (cat darwin-switch.log | grep --color error && exit 1) # todo: dynamic based on os


def rebuild():
    """
    Rebuilds the system's Nix configuration.
    Internally, it calls `$REBUILD_CMD switch --flake $NIX_FLAKE_PATH`, where $NIX_FLAKE_PATH is the
    path to the directory containing the flake.nix file (w.r.t this file's folder, its `./..`).
    $REBUILD_CMD is different depending on the system, and is either `darwin-rebuild` or
    `nixos-rebuild`.
    """

    match system():
        case "MacOS" | "Darwin":
            rebuild_cmd = "darwin-rebuild"
        case _:
            rebuild_cmd = "nixos-rebuild"  # Default to NixOS

    return invoke_process_popen_poll_live(
        [rebuild_cmd, "switch", "--verbose", "--flake", NIX_FLAKE_PATH],
        "🔄 Rebuilding",
    )


def git_commit_push():
    """
    Git commits and pushes the current changes to the upstream repository.
    """

    invoke_process_popen_poll_live(
        ["git", "commit", "-am", "Nix rebuild"],
        "📦 'git commit'-ing",
        cwd=NIX_FLAKE_PATH,
    )

    invoke_process_popen_poll_live(
        ["git", "push"],
        "📤 'git push'-ing",
        cwd=NIX_FLAKE_PATH,
    )


def git_pull():
    """
    Git pulls the latest changes from the upstream repository.
    """

    invoke_process_popen_poll_live(
        ["git", "pull"],
        "📥 'git pull'-ing",
        cwd=NIX_FLAKE_PATH,
    )


# Partially derived from:
# https://github.com/fabianlee/blogcode/blob/master/python/runProcessWithLiveOutput.py
def invoke_process_popen_poll_live(command, display, display_lines=5, cwd=None) -> int:
    """runs subprocess with Popen/poll so that live stdout is shown"""

    env = environ.copy()
    env["TERM"] = "dumb"

    print(f"{display}... ")

    with subprocess.Popen(
        command,
        shell=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        env=env,
        cwd=cwd,
    ) as process:
        proc_out = []

        while process.poll() is None:
            # Get output
            output = process.stdout.readline().strip().decode()
            if output == "":
                continue

            # Erase last `len(proc_out)` lines, prep. to write new ones
            # NOTE: len(proc_out) > 0 so that we don't erase the cmd invoke/prev. line
            if len(proc_out) > 0:
                print(f"\033[{len(proc_out)}A\033[J")

            # Update proc_out to be scrolling
            proc_out.append(output)
            if len(proc_out) > display_lines:
                proc_out = proc_out[1:]

            print(
                "\n".join(map(lambda x: f"\033[90m> {x}\x1b[0m", proc_out)),
                end="",
            )

        result = process.poll()

        if result is not None and result != 0:
            print("\n".join(map(lambda x: f"\033[0;31m{x}\033[0m", proc_out)))
        else:
            print(f"\033[{len(proc_out) + 1}A\033[J")
            print(f"{display}... Done! ✨")

        return process.poll()

    print(f"ERROR {sys.exc_info()[1]} while running {command.join(" ")}")
    return None
