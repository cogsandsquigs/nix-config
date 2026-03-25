{ pkgs, ... }:
{
    home.packages = with pkgs; [ eza ];

    programs.eza = {
        colors = "auto";
        git = true;
        icons = true;
    };
}
