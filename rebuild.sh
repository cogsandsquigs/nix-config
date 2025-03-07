# NOTE: Derived from https://gist.github.com/0atman/1a5133b842f929ba4c1e195ee67599d5

#!/usr/bin/env bash
#
# I believe there are a few ways to do this:
#
#    1. My current way, using a minimal /etc/nixos/configuration.nix that just imports my config from my home directory (see it in the gist)
#    2. Symlinking to your own configuration.nix in your home directory (I think I tried and abandoned this and links made relative paths weird)
#    3. My new favourite way: as @clot27 says, you can provide nixos-rebuild with a path to the config, allowing it to be entirely inside your dotfies, with zero bootstrapping of files required.
#       `nixos-rebuild switch -I nixos-config=path/to/configuration.nix`
#    4. If you uses a flake as your primary config, you can specify a path to `configuration.nix` in it and then `nixos-rebuild switch —flake` path/to/directory
# As I hope was clear from the video, I am new to nixos, and there may be other, better, options, in which case I'd love to know them! (I'll update the gist if so)

# A rebuild script that commits on a successful build
set -e

# Edit your config
$EDITOR /etc/nix # TODO: Make this dynamic

# cd to your config dir
pushd /etc/nix # TODO: Make this dynamic

# Early return if no changes were detected (thanks @singiamtel!)
if git diff --quiet '*.nix' '**/*.nix' '*.lock' 'home/**/*'; then
    echo "No changes detected, exiting."
    popd
    exit 0
fi

# Autoformat your nix files
alejandra . &>/dev/null \
  || ( alejandra . ; echo "formatting failed!" && exit 1)

# Shows your changes
git diff -U0 '*.nix' '**/*.nix' '*.lock' 'home/**/*'

echo "Nix Rebuilding..."

# Rebuild, output simplified errors, log trackebacks
darwin-rebuild switch --flake /etc/nix &>darwin-switch.log || (cat darwin-switch.log | grep --color error && exit 1) # TODO: Dynamic based on OS

# Get current generation metadata
current=$(darwin-rebuild --list-generations | grep current)

# Commit all changes witih the generation metadata
git commit -am "$current"

# Push all changes to upstream
git push

# Back to where you were
popd

# Notify all OK!
# notify-send -e "Nix Rebuilt OK!" --icon=software-update-available
