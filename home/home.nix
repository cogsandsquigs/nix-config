{pkgs, ...}: {
  home.stateVersion = "25.05";

  imports = [
    ./zsh.nix
    ./kitty.nix
    ./git.nix
    ./zoxide.nix
    ./eza.nix
    ./neovim
    ./p10k
  ];

  # User-only packages
  home.packages = with pkgs; [
    ## USERLAND ##
    # neovim # Editor NOTE: Removed, see here: https://discourse.nixos.org/t/home-manager-neovim-collision/16963
    kitty # Terminal
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
    ripgrep
    neofetch
    jq

    ## DEVELOPMENT ##

    # C/C++
    cmake

    # Python
    python3
    black # Formatter
    pyright # Typechecker
    pylint # Linter

    # Nodejs
    nodejs_23
    bun
    # Ruby
    rbenv

    # Rust
    rustup

    # Java/Kotlin
    jdk21
    gradle
    kotlin
    jetbrains.idea-ultimate

    # nix
    alejandra # Formatter

    # Latex
    texliveFull # Install `latexmk` + co (unneeded) for vimtex (see neovim config)

    ## FUN ##
    modrinth-app # Minecraft launcher

    ## MISCELLANEOUS ##
    magic-wormhole
    discord # For some reason discord is availabe on mac via nixpkgs, but not firefox???
    fontconfig
    obsidian
  ];
}
