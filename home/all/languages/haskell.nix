{ pkgs, ... }:
{
    home.packages = with pkgs; [
        ghc
        haskellPackages.cabal-install
        haskellPackages.fourmolu
        haskellPackages.haskell-language-server
        haskellPackages.hlint
    ];
}
