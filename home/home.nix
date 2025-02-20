{pkgs, ...}: {
  home.stateVersion = "25.05";

  # User-only packages
  home.packages = with pkgs; [
    ## DEVELOPMENT ##
    kitty # Terminal
    neovim # Editor
    git # <3
    lazygit # Makes git awesomer
    gnupg # Signatures
    delta # Git diff highlighting
    zoxide # Better CD
    zsh
    oh-my-zsh
    zsh-powerlevel10k

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

  imports = [
    ./zsh.nix
    ./kitty.nix
    ./git.nix
  ];
}
