{pkgs, ...}: {
    home.stateVersion = "25.05";

    imports = [
        ./shell.nix
        ./kitty.nix
        ./git.nix
        ./zoxide.nix
        ./eza.nix
        ./neovim
        ./p10k
        ./librewolf.nix
        ./direnv.nix
    ];

    # User-only packages
    home.packages = with pkgs; [
        ## SHELLS ##

        # Zsh
        zsh
        oh-my-zsh
        zsh-powerlevel10k

        # Fish
        fish

        ## USERLAND ##

        kitty # Terminal
        # neovim # Editor NOTE: Removed, see here: https://discourse.nixos.org/t/home-manager-neovim-collision/16963
        git # <3
        lazygit # Makes git awesomer
        gnupg # Signatures
        delta # Git diff highlighting
        zoxide # Better CD
        fzf # Fuzzy finder
        eza # Better ls
        dust # Better du
        bat # Better cat
        ripgrep
        neofetch
        jq
        tree-sitter

        ## DEVELOPMENT ##

        # C/C++
        llvm
        clang
        clang-analyzer
        cmake

        # Docker/VMs
        docker
        docker-compose
        colima
        lima

        # Documentation generation
        mdbook # Docs from MD: https://rust-lang.github.io/mdBook/index.html

        # Haskell
        ghc
        haskell-language-server
        cabal-install

        # Java/Kotlin
        jdk
        gradle
        kotlin
        jetbrains.idea-ultimate

        # Latex
        texliveFull # Install `latexmk` + co (unneeded) for vimtex (see neovim config)

        # Nix
        alejandra # Formatter
        # direnv # NOTE: Not needed! See: https://github.com/nix-community/nix-direnv

        # Nodejs
        nodejs
        bun
        deno

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
        modrinth-app # Minecraft launcher

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
        postman
        kicad
    ];
}
