{
    flake.modules.homeManager."apps/zoom" = { pkgs, ... }: { home.pacakges = with pkgs; [ zoom-us ]; };
}
