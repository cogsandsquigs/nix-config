{ pkgs, ... }:
{
  # User-only packages
  home.packages = with pkgs; [
    # Zsh
    zsh
    oh-my-zsh
    zsh-powerlevel10k

    # Fish
    fish
    starship # Like P10k but for any shell
  ];
}
