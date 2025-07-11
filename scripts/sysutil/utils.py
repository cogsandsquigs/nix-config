"""
Utilities to update and upgrade the Nix configuration.
"""

import subprocess
import sys
from os import environ, get_terminal_size, path
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

    if system() in ["MacOS", "Darwin"]:
        rebuild_cmd = "darwin-rebuild"
    else:
        rebuild_cmd = "nixos-rebuild"  # Default to NixOS

    # NOTE: Syntax for py >= 3.10
    #
    # match system():
    #     case "MacOS" | "Darwin":
    #         rebuild_cmd = "darwin-rebuild"
    #     case _:
    #         rebuild_cmd = "nixos-rebuild"  # Default to NixOS

    return invoke_process_popen_poll_live(
        ["sudo", rebuild_cmd, "switch", "--verbose", "--flake", NIX_FLAKE_PATH],
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
        ignore_errors=True,
    )

    invoke_process_popen_poll_live(
        ["git", "push"],
        "📤 'git push'-ing",
        cwd=NIX_FLAKE_PATH,
        ignore_errors=True,
    )


def git_pull():
    """
    Git pulls the latest changes from the upstream repository.
    """

    invoke_process_popen_poll_live(
        ["git", "pull"],
        "📥 'git pull'-ing",
        cwd=NIX_FLAKE_PATH,
        ignore_errors=True,
    )


def nix_gc():
    """
    Gets rid of old generations of Nix packages.
    See: https://www.reddit.com/r/NixOS/comments/1j70gew/how_to_clean_nixstore/
    """

    invoke_process_popen_poll_live(
        ["nix", "store", "gc"],
        "🗑️ Cleaning out the Nix store",
        cwd=NIX_FLAKE_PATH,
        ignore_errors=False,
    )

    invoke_process_popen_poll_live(
        ["home-manager", "expire-generations", "-d"],
        "🗑️ Cleaning old Home Manager generations",
        cwd=NIX_FLAKE_PATH,
        ignore_errors=False,
    )

    invoke_process_popen_poll_live(
        ["nix", "profile", "wipe-history"],
        "🗑️ Wiping Nix profile history",
        cwd=NIX_FLAKE_PATH,
        ignore_errors=False,
    )


# Partially derived from:
# https://github.com/fabianlee/blogcode/blob/master/python/runProcessWithLiveOutput.py
def invoke_process_popen_poll_live(
    command, display, display_lines=5, cwd=None, ignore_errors=False
) -> int:
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
        num_displayed_lines = 0

        while process.poll() is None:
            # Get output
            output = process.stdout.readline().strip().decode()
            if output == "":
                continue

            # Erase last `display_lines` or `len(proc_out)` lines, prep. to write new ones
            # NOTE: len(proc_out) > 0 so that we don't erase the cmd invoke/prev. line
            if num_displayed_lines > 0:
                max_width = get_terminal_size().columns
                real_displayed_lines = (
                    sum(
                        map(
                            lambda line: (len(line) % max_width)
                            + (len(line) // max_width),
                            proc_out[-num_displayed_lines:],
                        )
                    )
                    - 1  # NOTE: `-1` since it rms 1 more line than necessary
                )
                print("\x1b[1A\x1b[2K" * real_displayed_lines, end="")

            proc_out.append(output)
            num_displayed_lines = min(len(proc_out), display_lines)

            print(
                "\n".join(
                    map(
                        lambda x: f"\033[90m> {x}\x1b[0m",
                        proc_out[-num_displayed_lines:],
                    )
                ),
                end="",
            )

        result = process.poll()

        if result is not None and result != 0 and not ignore_errors:
            print("\n\033[1;31mERROR:\033[0m")
            print("\n".join(map(lambda x: f"\033[0;31m{x}\033[0m", proc_out)))
            sys.exit()
        else:
            print(f"\033[{num_displayed_lines + 1}A\033[J")
            print(f"{display}... Done! ✨")

        return process.poll()

    print(f"ERROR {sys.exc_info()[1]} while running {command.join(' ')}")
    return None
