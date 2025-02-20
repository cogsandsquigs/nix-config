{pkgs, ...}: {
  home.stateVersion = "25.05";

  # User-only packages (basically just shell + plugins)
  home.packages = with pkgs; [
    zsh
    oh-my-zsh
    zsh-powerlevel10k
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
    history.size = 10000;

    plugins = [
      {
        name = "zsh-powerlevel10k";
        src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    # Enable powerlevel10k theme
    # promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

    shellAliases = {
      ls = "ls --color";
      nv = "nvim";
      rebuild = "/etc/nix/rebuild.sh";
    };

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = ["git"];
    };
  };
}
