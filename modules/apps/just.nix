# Just -- modern `make`
{
    flake.modules.homeManager."apps/just" = { pkgs, ... }: {
        home.packages = with pkgs; [
            just
            fzf # Dependency of just
        ];
    };
}
