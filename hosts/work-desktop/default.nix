# work-desktop — x86_64-linux work machine running Ubuntu 24.
#
# This is NOT a NixOS/nix-darwin system: Nix is installed per-user, and this config is applied
# with *standalone* home-manager (`home-manager switch --flake ...#ipratt@work-desktop`). It
# therefore does NOT go through modules/system/* or modules/home-manager.nix — the flake builds
# it directly via lib.mkHome, which imports the shared home CORE (modules/home) and this file.
#
# The core is the "develop + as-needed" baseline (shell, terminal, CLI utils, full dev
# toolchain). It deliberately excludes the personal profile (games, Discord, Obsidian, …) that
# modules/home/personal.nix layers on for the personal machines.
#
# Everything machine-specific is a small `my.*` override or a `home.*` setting below, so pointing
# this at a different user/host later is a one- or two-line change.
{ config, ... }:
let
    username = "ipratt";
in
{
    # Standalone home-manager must be told who it is (there's no system user account to inherit
    # from). base.nix derives home.homeDirectory = /home/${username} on Linux from this.
    home.username = username;

    # This flake is checked out at ~/.config/nix on the work box (a per-user Nix install), rather
    # than /etc/nix as on the system hosts. Drives the rebuild/upgrade/… shell aliases.
    my.flakeDir = "${config.home.homeDirectory}/.config/nix";

    # Work git identity. Signing is off so commits work out of the box on a machine that doesn't
    # have the personal GPG key. To sign with a work key later: import the key, then set
    #   my.git.signingKey = "<key-id>"; my.git.signByDefault = true;
    my.git = {
        email = "ian.pratt@arcticlake.com";
        signingKey = null;
        signByDefault = false;
    };
}
