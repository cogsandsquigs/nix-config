{ pkgs, ... }:
{
    home.packages =
        let
            # NOTE: As of 2026-02-27, `haskellPackages.cabal-install` and `haskellPackages.fourmolu`
            # have a conflicting subpath when evaluating them. We will ignore their collisions so both
            # can be installed together.
            haskellPackages = pkgs.haskellPackages.override (args: {
                ignoreCollisions = true;
            });
        in
        [
            pkgs.ghc
            haskellPackages.haskell-language-server
            haskellPackages.hlint
            haskellPackages.cabal-install
            haskellPackages.fourmolu
        ];
}
