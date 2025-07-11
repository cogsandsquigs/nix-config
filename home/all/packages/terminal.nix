{ pkgs, ... }:
{
    home.packages = with pkgs; [
        kitty # Terminal
        alacritty # Terminal
        zellij # Terminal multiplexer
    ];
}
