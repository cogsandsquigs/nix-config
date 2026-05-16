# Torrenting apps
{ ... }:
{
    flake.modules.homeManager.torrenting =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [ qbittorrent ];
        };
}
