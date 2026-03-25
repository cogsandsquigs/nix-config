## NOTE: This is just all JS/TS/HTML/CSS stuff ##

{ pkgs, ... }:
{
    home.packages = with pkgs; [
        nodejs
        bun

        typescript-language-server # JS/TS langserv
        prettierd
    ];
}
