## NOTE: This is just all JS/TS/HTML/CSS stuff ##

{ pkgs, ... }:
{
    home.packages = with pkgs; [
        zola
        vscode-langservers-extracted # HTML/CSS langserv
        prettierd
    ];
}
