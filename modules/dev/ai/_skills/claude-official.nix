# Anthropic's managed plugins, reduced to their skills. Only the plugins that
# carry a skills/ subdir are kept; ralph-loop ships hooks and commands but no
# skills, so it has nothing here. A fetcher rather than a flake input, so
# `nix flake update` cannot move the pinned skills underneath us.
{ pkgs, ... }:
let
    src = pkgs.fetchFromGitHub {
        owner = "anthropics";
        repo = "claude-plugins-official";
        rev = "892bf62a0d8d0de53025fe8b2a3d35e45cc10c55";
        hash = "sha256-U2cD8CrL54zz8wrbq4OypFCKeAPvRrS/6GbMQTjjbuc=";
    };
in
map (n: "${src}/plugins/${n}/skills") [
    "claude-md-management"
    "skill-creator"
]
