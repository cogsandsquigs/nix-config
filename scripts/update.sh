export NIX_DIR="$(dirname -- $( readlink -f -- '$0'))/.."

nix flake update $NIX_DIR
