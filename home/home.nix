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
    autocd = true;

    # Enable powerlevel10k theme
    initExtraFirst = "~/.p10k.zsh";

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

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
