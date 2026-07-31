# work-desktop -- x86_64-linux work machine running Ubuntu 24.
#
# This is NOT a NixOS/nix-darwin system: Nix is installed per-user, and this config is applied with
# *standalone* home-manager (`home-manager switch --flake ...#ipratt@work-desktop`). Its `class` is
# "home" (see ./id.nix), so it does not go through the system-class features --
# tools/default.nix builds it directly from the user unit.
#
# There is nothing host-specific left here: identity, the home feature set, git identity, and the
# flake checkout path all live in the portable user unit (users/ipratt/), and home.username + platform
# come from ./id.nix. This file remains the host module, and is the place for any genuinely
# work-box-only home overrides if they ever arise.
_: { _class = "homeManager"; }
