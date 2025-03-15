{pkgs, ...}: {
  home.stateVersion = "25.05";

  imports = [
    ./zsh.nix
    ./fish.nix
    ./kitty.nix
    ./git.nix
    ./zoxide.nix
    ./eza.nix
    ./neovim
    ./p10k
    ./librewolf.nix
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
    fish
    zsh-powerlevel10k
    eza # Better ls
    dust # Better du
    bat # Better cat
    ripgrep
    neofetch
    jq

    ## DEVELOPMENT ##

    # C/C++
    clang
    cmake
    llvmPackages.clang-tools # tools for clang!

    # Docker/VMs
    docker
    docker-compose
    colima
    lima

    # Documentation generation
    mdbook # Docs from MD: https://rust-lang.github.io/mdBook/index.html

    # Java/Kotlin
    jdk
    gradle
    kotlin
    jetbrains.idea-ultimate

    # Latex
    texliveFull # Install `latexmk` + co (unneeded) for vimtex (see neovim config)

    # Nix
    alejandra # Formatter

    # Nodejs
    nodejs_23
    bun

    # Python
    python3
    black # Formatter
    pyright # Typechecker
    pylint # Linter

    # Ruby
    rbenv

    # Rust
    rustup
    #cargo-afl # Fuzzing
    cargo-watch
    cargo-workspaces

    ## FUN ##
    # modrinth-app # Minecraft launcher # NOTE: Disabled for now due to issues w/ compile
    ghidra-bin # just a lil silly :3

    ## MISCELLANEOUS ##
    magic-wormhole
    discord # For some reason discord is availabe on mac via nixpkgs, but not firefox???
    fontconfig
    obsidian
    # NOTE: Why `firefox-unwrapped` and not `firefox`?
    # See: https://github.com/NixOS/nixpkgs/issues/366581
    # NOTE: Why no use? B/c not preserving firefox config thru reinstalls.
    # So use homebrew to install on mac
    # firefox-unwrapped
    librewolf
    spotify
  ];
}
