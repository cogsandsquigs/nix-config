#!/bin/bash

sudo -i nix-env --delete-generations old
sudo -i nix-store --gc
sudo -i nix-collect-garbage -d
