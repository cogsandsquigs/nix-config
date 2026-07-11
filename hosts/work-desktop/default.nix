# work-desktop — x86_64-linux work machine running Ubuntu 24.
#
# This is NOT a NixOS/nix-darwin system: Nix is installed per-user, and this config is applied
# with *standalone* home-manager (`home-manager switch --flake ...#ipratt@work-desktop`). It
# therefore does NOT go through modules/system/* or modules/home-manager.nix — the flake builds
# it directly via lib.mkHome.
#
# There is nothing host-specific left here: identity, the home feature set, git identity, and the
# flake checkout path all live in the portable user unit (users/ipratt/), and home.username +
# platform come from ./id.nix via mkHome. This file remains as the host module mkHome imports, and
# is the place for any genuinely work-box-only home overrides if they ever arise.
{ ... }: { }
