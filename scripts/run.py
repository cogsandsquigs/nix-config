"""
Runs/Rebuilds/Updates the Nix configuration
"""

import argparse

from utils import git_commit_push, git_pull, rebuild, update

parser = argparse.ArgumentParser(
    prog="NixRunner",
    description="Runs/Rebuilds/Updates the Nix configuration",
    epilog="Made with <3 by Ian",
)

parser.add_argument("action")  # positional argument

args = parser.parse_args()

match args.action:
    case "rebuild":
        git_pull()
        rebuild()
        git_commit_push()

    case "upgrade" | "update":
        git_pull()
        update()
        rebuild()
        git_commit_push()
