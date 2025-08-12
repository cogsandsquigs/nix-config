{ pkgs, ... }:
{
    home.packages = with pkgs; [
        nodejs
        bun

        # Utils
        typescript-language-server
        prettierd
    ];
}
