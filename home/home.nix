{pkgs, ...}: {
  home.stateVersion = "25.05";

  programs.zsh = {
    enable = true;

    shellAliases = {
      ls = "ls --color";
      nv = "nvim";
      rebuild = "/etc/nix/rebuild.sh";
    };

    /*
    ohMyZsh = {
      enable = true;
      plugins = ["git" "zsh-autosuggestions" "zsh-syntax-highlighting"];
    };
    */
  };
}
