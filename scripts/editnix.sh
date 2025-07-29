#!/bin/sh

cd /etc/nix

$EDITOR # Open da editorrrr

git add . # Make sure nix sees all changes!

python3 ./scripts/sysutil/run.py rebuild

# cd -
