# The shell configuration I use!
{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history.size = 10000;
    autocd = true;

    # Enable powerlevel10k theme
    initExtra =
      "source /etc/profile.d/nix.sh\n" # Source nix environment variables
      + "source ~/.p10k.zsh\n"; # Source powerlevel10k theme

    envExtra =
      "export EDITOR=nvim\n" # Set default editor to nvim
      + "export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))\n"
      + "export CC=${pkgs.clang}"
      + "export AR=${pkgs.llvm}";

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    shellAliases = {
      ls = "eza --icons";
      du = "dust";
      cat = "bat"; # Better cat via `bat`
      cd = "z"; # Better cd via `zoxide`
      nv = "nvim";
      upgrade = "python3 /etc/nix/scripts/run.py upgrade";
      rebuild = "python3 /etc/nix/scripts/run.py rebuild";
    };

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = ["git"];
    };
  };

  programs.fish = {
    enable = false;
  };
}
