{pkgs, ...}: {
    home.stateVersion = "25.05"; # Home Manager version

    imports = [
        ./shell.nix
        ./kitty.nix
        ./git.nix
        ./zoxide.nix
        ./eza.nix
        ./neovim
        ./librewolf.nix
        ./direnv.nix
        ./starship.nix
        ./gpg.nix
        ./gpg-agent.nix
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
        starship # Like P10k but for any shell

        ## USERLAND ##

        kitty # Terminal
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
        just
        tree-sitter
        tree
        fastfetch # System info

        ## DEVELOPMENT ##

        # Editor/IDE
        # neovim # Editor NOTE: Removed, see here: https://discourse.nixos.org/t/home-manager-neovim-collision/16963
        python313Packages.pylatexenc # Needed for converting inline LaTeX in MD to unicode

        # C/C++
        # NOTE: Using LLVM v20 for C/C++ development
        bear
        cmake
        llvmPackages_20.clang
        llvmPackages_20.clang-tools
        clang-analyzer # Not in LLVM pkgs :/
        platformio # hardware stuffs
        pkg-config
        # valgrind # Memory profiler/debugger # NOTE: Currently broken :/

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

        # SSG/Webdev
        zola

        ## FUN ##
        modrinth-app-unwrapped # Minecraft launcher

        ## MISCELLANEOUS ##
        magic-wormhole

        discord # For some reason discord is availabe on mac via nixpkgs, but not firefox???
        fontconfig
        obsidian
        librewolf
        spotify
        postman
        # kicad-testing
        # NOTE: Why `firefox-unwrapped` and not `firefox`?
        # See: https://github.com/NixOS/nixpkgs/issues/366581
        # NOTE: Why no use? B/c not preserving firefox config thru reinstalls.
        # So use homebrew to install on mac
        # firefox-unwrapped
    ];
}
