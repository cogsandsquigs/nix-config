{ pkgs, lib, ... }:
{
    home.packages = with pkgs; [
        ghc
        haskellPackages.haskell-language-server
        haskellPackages.hlint

        # NOTE: As of 2026-02-27, `haskellPackages.cabal-install` and `haskellPackages.fourmolu`
        # have a conflicting subpath when evaluating them. We set
        # `haskellPackages.cabal-install` as the higher-priority package for colliding names.
        (lib.hiPrio haskellPackages.cabal-install)
        haskellPackages.fourmolu
    ];
}
