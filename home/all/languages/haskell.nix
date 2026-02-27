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
.override
    (args: {
        # NOTE: As of 2026-02-27, `haskellPackages.cabal-install` and `haskellPackages.fourmolu`
        # have a conflicting subpath when evaluating them. We will ignore their collisions so both
        # can be installed together.
        ignoreCollisions = true;
    })
