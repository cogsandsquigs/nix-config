{pkgs, ...}: {
  home.stateVersion = "25.05";

  imports = [
    ./zsh.nix
    ./kitty.nix
    ./git.nix
    ./zoxide.nix
    ./eza.nix
    ./neovim
  ];

  # User-only packages
  home.packages = with pkgs; [
    ## USERLAND ##
    kitty # Terminal
    # neovim # Editor NOTE: Removed, see here: https://discourse.nixos.org/t/home-manager-neovim-collision/16963
    git # <3
    lazygit # Makes git awesomer
    gnupg # Signatures
    delta # Git diff highlighting
    zoxide # Better CD
    fzf # Fuzzy finder
    zsh
    oh-my-zsh
    zsh-powerlevel10k
    eza # Better ls
    dust # Better du
    bat # Better cat

    ## DEVELOPMENT ##

    # Nodejs
    nodejs_23
    bun

    # Ruby
    rbenv

    # Rust
    rustup

    # Kotlin
    jetbrains.idea-ultimate

    # nix
    alejandra # Formatter

    ## FUN ##
    modrinth-app # Minecraft launcher

    ## MISCELLANEOUS ##
    magic-wormhole
    discord # For some reason discord is availabe on mac via nixpkgs, but not firefox???
    fontconfig
    obsidian
  ];
}
