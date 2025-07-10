{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git # <3
    lazygit # Makes git awesomer
    delta # Git diff highlighting
  ];
}
