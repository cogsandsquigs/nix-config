{ pkgs, ... }:
{
    home.packages = with pkgs; [
        svelte-language-server
        prettierd
    ];
}
