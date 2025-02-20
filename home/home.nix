{pkgs, ...}: {
  home.stateVersion = "25.05";

  # User-only packages (basically just shell + plugins)
  home.packages = with pkgs; [
    delta # Git diff highlighting
    zsh
    oh-my-zsh
    zsh-powerlevel10k
  ];

  imports = [
    ./zsh.nix
    ./kitty.nix
    ./git.nix
  ];
}
