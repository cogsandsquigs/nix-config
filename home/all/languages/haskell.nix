{ pkgs, ... }:
{
    home.packages = with pkgs; [
        ghc
        haskellPackages.haskell-language-server
        haskellPackages.hlint

        # NOTE: As of 2026-02-27, `haskellPackages.cabal-install` and `haskellPackages.fourmolu`
        # have a conflicting subpath when evaluating them. We will ignore their collisions so both
        # can be installed together.
        (haskellPackages.cabal-install.override (args: {
            ignoreCollisions = true;
        }))
        (haskellPackages.fourmolu.override (args: {
            ignoreCollisions = true;
        }))
    ];
}
