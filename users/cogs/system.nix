# System account for `cogs` on a full-OS host (NixOS or nix-darwin). Class-portable: the
# NixOS-only attrs (`isNormalUser`, `extraGroups`) are omitted on darwin, which rejects them.
# Standalone home-manager hosts (per-user Nix, no system layer) never import this.
{ pkgs, lib, ... }: {
  my.sys.vpn.enable = true;

  users.users.cogs = {
    description = "cogs";
    shell = pkgs.fish;
  }
  // lib.optionalAttrs pkgs.stdenv.isLinux {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
