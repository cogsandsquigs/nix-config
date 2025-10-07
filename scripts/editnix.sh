#!/bin/bash

export NIX_CONF_DIR=/etc/nix
export SCRIPTS_PATH=$NIX_CONF_DIR/scripts

cd $NIX_CONF_DIR || exit 1

$EDITOR # Open da editorrrr

git add . # Make sure nix sees all changes!

python3 $SCRIPTS_PATH/rebuild.sh
