{ pkgs, ... }:
{
    home.packages = with pkgs; [
        qbittorrent
        python313Packages.opencv-python-headless # For some reason this is required to run qbittorrent???
    ];
}
