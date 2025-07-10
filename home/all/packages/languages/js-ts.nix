{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs
    bun
    deno

    # Utils
    typescript-language-server
    prettierd
  ];
}
