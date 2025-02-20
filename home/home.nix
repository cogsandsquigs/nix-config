{pkgs, ...}: {
  home.stateVersion = "25.05";

  # User-only packages (basically just shell + plugins)
  home.packages = with pkgs; [
    zsh
    oh-my-zsh
    zsh-powerlevel10k
  ];

  imports = [
    ./zsh.nix
    ./kitty.nix
  ];
}
