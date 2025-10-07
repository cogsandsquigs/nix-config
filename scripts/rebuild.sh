#!/bin/bash

export NIX_CONF_DIR=/etc/nix

cd $NIX_CONF_DIR || exit 1

# Pull changes, and make sure all files and file changes are recognized by nix
git fetch
git add .

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export NIX_REBUILD_CMD=nixos-rebuild
elif [[ "$OSTYPE" == "darwin"* ]]; then
    export NIX_REBUILD_CMD=darwin-rebuild
else
    echo "Unsupported operating system! Can't rebuild :("
    exit 1
fi

sudo -i $NIX_REBUILD_CMD switch --flake $NIX_CONF_DIR

# If all goes well, commit and push!
git commit -m "Nix rebuild"
git push
