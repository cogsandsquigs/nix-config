{ pkgs, ... }:
{
    home.packages = with pkgs; [
        # For some reason, this breaks on MacOS b/c wayland dependency (??)
        # qbittorrent
    ];
}
