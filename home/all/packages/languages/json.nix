{ pkgs, ... }:
{
  home.packages = with pkgs; [
    vscode-json-languageserver
    jsonnet-language-server
  ];
}
