{ pkgs, ... }:
{
    home.packages = with pkgs; [
        # NOTE: While used to serve caddyfiles, also is a formatter
        caddy
    ];
}
