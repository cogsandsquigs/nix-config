{ lib, ... }:
{
    flake.modules.homeManager.browser =
        { config, pkgs, ... }:
        {
            # NOTE: Add when ladybird browser becomes stable!!
            # home.packages = with pkgs; [ ladybird ];
        };
}
