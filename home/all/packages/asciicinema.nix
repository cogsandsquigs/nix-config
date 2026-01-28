{ pkgs, ... }:
{
    # User-only packages
    home.packages = with pkgs; [ asciicinema ];
}
