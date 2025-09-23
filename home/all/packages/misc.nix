{ pkgs, ... }:
{
    home.packages = with pkgs; [
        discord # For some reason discord is availabe on mac via nixpkgs, but not firefox???
        obsidian
        # spotify
        # postman
        zoom-us
        # inetutils
        # kicad-testing
    ];
}
