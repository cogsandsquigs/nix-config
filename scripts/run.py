"""
Runs/Rebuilds/Updates the Nix configuration
"""

import argparse

from utils import git_commit_push, git_pull, nix_gc, rebuild, update

parser = argparse.ArgumentParser(
    prog="NixRunner",
    description="Runs/Rebuilds/Updates the Nix configuration",
    epilog="Made with <3 by Cogs",
)

parser.add_argument("action")  # positional argument

args = parser.parse_args()

# NOTE: This is only for python >= 3.10, but macos uses 3.9, so I gotta use if-stuffs. Why care
# about this? Since `launchd` scripts don't necessarily use the terminal, they don't have the same
# environment variables as the terminal. Therefore, the `python3` command is not the same as the
# `python3` command that Nix loads installs. This means that `launchd` uses the default MacOS
# python, which is Python 3.9
if args.action == "rebuild":
    git_pull()
    rebuild()
    git_commit_push()
elif args.action == "upgrade":
    git_pull()
    update()
    rebuild()
    git_commit_push()
elif args.action == "cleanup":
    nix_gc()
else:
    print("Invalid action. Please choose 'rebuild', 'upgrade', or 'cleanup'.")

# NOTE: Syntax for py >= 3.10
#
# match args.action:
#    case "rebuild":
#        git_pull()
#        rebuild()
#        git_commit_push()

#    case "upgrade":
#        git_pull()
#        update()
#        rebuild()
#        git_commit_push()
#
#    default:
#       print("Invalid action. Please choose either 'rebuild' or 'upgrade'.")
