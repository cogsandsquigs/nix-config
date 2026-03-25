{ pkgs, ... }:
{
    /*
      programs.nix-ld = {
          enable = true;

          # NOTE: Add any missing dynamic libraries for unpackaged programs
          # here, NOT in environment.systemPackages.
          libraries = with pkgs; [
          ];
      };
    */
    environment.systemPackages = with pkgs; [ ];
}
