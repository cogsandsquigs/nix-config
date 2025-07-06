#!/bin/sh

cd /etc/nix 

$EDITOR

python3 ./scripts/sysutil/run.py rebuild

# cd -
