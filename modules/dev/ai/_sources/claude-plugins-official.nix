# Anthropic's managed plugin directory. A fetcher rather than a flake input, so `nix flake update`
# cannot move third-party agent instructions underneath us -- bumping this is a deliberate edit of
# `rev`, then the hash the build reports.
#
# One upstream, several plugins, so this file names the three worth having.
{ pkgs, lib, ... }:
let
    src = pkgs.fetchFromGitHub {
        owner = "anthropics";
        repo = "claude-plugins-official";
        rev = "892bf62a0d8d0de53025fe8b2a3d35e45cc10c55";
        hash = "sha256-U2cD8CrL54zz8wrbq4OypFCKeAPvRrS/6GbMQTjjbuc=";
    };
in
lib.genAttrs [ "claude-md-management" "ralph-loop" "skill-creator" ] (
    name: "${src}/plugins/${name}"
)
