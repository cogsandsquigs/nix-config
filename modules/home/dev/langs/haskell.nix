{ pkgs, lib, ... }: {
    lang = [ "haskell" ];

    pkgs = with pkgs; [
        ghc
        haskellPackages.haskell-language-server
        haskellPackages.hlint
        # NOTE: As of 2026-02-27, `haskellPackages.cabal-install` and `haskellPackages.fourmolu`
        # have a conflicting subpath. cabal-install is set higher-priority for colliding names.
        (lib.hiPrio haskellPackages.cabal-install)
        haskellPackages.fourmolu
    ];

    lsp = [
        {
            name = "haskell-language-server";
            cmd  = [ "haskell-language-server-wrapper" "--lsp" ];
            config.haskell = {
                formattingProvider = "fourmolu";
                plugin = {
                    fourmolu.config.external = true;
                    hlint.diagnosticsOn = false; # https://github.com/haskell/haskell-language-server/issues/4674
                    rename.config.crossModule = true; # https://github.com/haskell/haskell-language-server/issues/3571
                };
            };
        }
    ];

    fmt = [
        "fourmolu"
        "--stdin-input-file=%{buffer_name}"
        "--column-limit=100"
        "--comma-style=trailing"
        "--function-arrows=leading"
        "--haddock-style=single-line"
        "--haddock-style-module=single-line"
        "--if-style=hanging"
        "--import-export-style=diff-friendly"
        "--indentation=4"
        "--indent-wheres=true"
        "--in-style=left-align"
        "--let-style=mixed"
        # "--record-style=knr" # Unreleased as of 2025-11-30!
        "--single-constraint-parens=always"
        "--single-deriving-parens=always"
        "--sort-constraints=true"
        "--sort-derived-classes=true"
        "--sort-deriving-clauses=true"
        "--trailing-section-operators=false"
    ];

    roots.haskell = [
        "Setup.hs"
        "stack.yaml"
        "*.cabal"
        "*.hs"
        "*.lhs"
    ];
}
