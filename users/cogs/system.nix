# System account for `cogs` on a full-OS host. Keyed by class, like a feature under modules/, because
# the two classes accept different attributes: `isNormalUser` and `extraGroups` are NixOS-only and
# nix-darwin rejects them. Splitting by class replaces the branch on
# `lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux` that used to hide that difference inside one
# attribute set.
#
# A standalone home-manager host has no system layer and never reads this file.
let
    account = {
        description = "cogs";
    };
in
{
    nixos = { pkgs, ... }: {
        users.users.cogs = account // {
            shell = pkgs.fish;
            isNormalUser = true;
            extraGroups = [ "wheel" ];
        };
    };

    darwin = { pkgs, ... }: {
        users.users.cogs = account // {
            shell = pkgs.fish;
        };
    };
}
