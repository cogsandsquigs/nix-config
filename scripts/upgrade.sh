#!/bin/bash

export NIX_CONF_DIR=/etc/nix
export SCRIPTS_PATH=$NIX_CONF_DIR/scripts

sudo -i nix flake update --flake $NIX_CONF_DIR

# rebuild system
$SCRIPTS_PATH/rebuild.sh
