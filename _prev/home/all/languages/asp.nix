{ pkgs, ... }:
{
    home.packages = with pkgs; [ clingo ];
}
