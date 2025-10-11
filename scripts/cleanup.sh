#!/bin/bash

#export NIX_STORE=/nix
#export DU_CMD=/usr/bin/du
#export

#dir_size() {
#    local dir, size
#
#    dir=$1
#    size=$($DU_CMD -B1 -s "$dir" | awk '{sum += $1} END{print sum}')
#
#}

#$DU_CMD -B1 -s $NIX_STORE | awk '{sum += $1} END{print sum}'

sudo -i nix-env --delete-generations old
sudo -i nix-store --gc
sudo -i nix-collect-garbage -d
