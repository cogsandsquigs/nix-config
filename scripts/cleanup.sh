#!/usr/bin/env bash

set -e # exit if any command errors

sudo -i nix-env --delete-generations old
sudo -i nix-store --gc
sudo -i nix-collect-garbage -d
