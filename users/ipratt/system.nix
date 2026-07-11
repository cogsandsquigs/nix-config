# System account for `ipratt` on a full-OS host — see users/cogs/system.nix for the convention.
# The work box itself is standalone home-manager (no system layer), so this only matters if the
# work user is ever placed on a NixOS/darwin host.
{ pkgs, lib, ... }: {
    users.users.ipratt = {
        description = "ipratt";
        shell = pkgs.fish;
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
    };
}
