{
    flake.modules.homeManager."apps/zoom" = { pkgs, ... }: { home.packages = with pkgs; [ zoom-us ]; };
}
