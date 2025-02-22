import argparse

from utils import git_commit_push, rebuild, update

parser = argparse.ArgumentParser(
    prog="NixRunner",
    description="Runs/Rebuilds/Updates the Nix configuration",
    epilog="Made with <3 by Ian",
)

parser.add_argument("action")  # positional argument

args = parser.parse_args()

match args.action:
    case "rebuild":
        rebuild()
        git_commit_push()

    case "upgrade" | "update":
        update()
        rebuild()
        git_commit_push()
