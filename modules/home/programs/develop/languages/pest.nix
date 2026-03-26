{ ... }:
{
    flake.modules.homeManager.develop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                pest-ide-tools # Installs pest LSP
            ];
        };
}
