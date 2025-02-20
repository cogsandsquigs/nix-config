{pkgs, ...}: {
  home.stateVersion = "25.05";

  # User-only packages (basically just shell + plugins)
  home.packages = with pkgs; [
    zsh
    oh-my-zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];

  programs.zsh = {
    enable = true;

    shellAliases = {
      ls = "ls --color";
      nv = "nvim";
      rebuild = "/etc/nix/rebuild.sh";
    };

    oh-my-zsh = {
      enable = true;
      theme = "robbyrusell";
      plugins = ["git" "zsh-autosuggestions" "zsh-syntax-highlighting"];
    };
  };
}
