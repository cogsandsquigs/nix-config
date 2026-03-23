{ pkgs, ... }:
{
    home.packages = with pkgs; [ sherlock ];
}
