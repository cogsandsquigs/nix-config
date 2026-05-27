{ ... }:
{

    flake.modules.homeManager.ide =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [ jetbrains.idea ];
        };
}
