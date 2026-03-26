{ ... }:
{
    flake.modules.homeManager.develop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [ yaml-language-server ];
        };
}
