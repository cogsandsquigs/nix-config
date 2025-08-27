{ pkgs, ... }:
{
    home.packages = with pkgs; [
        deluge
        deluge-gtk
    ];
}
