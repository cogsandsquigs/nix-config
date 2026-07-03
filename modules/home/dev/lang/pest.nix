{ ... }:
{
  flake.modules.homeManager.dev.lang =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        pest-ide-tools # Installs pest LSP
      ];
    };
}
