{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kitty # Terminal
    zellij # Terminal multiplexer
  ];
}
