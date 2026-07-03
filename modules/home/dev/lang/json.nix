{ ... }:
{
  flake.modules.homeManager.dev.lang =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        vscode-langservers-extracted
        jsonnet-language-server
      ];
    };
}
