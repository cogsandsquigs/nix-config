{ ... }:
{
    flake.modules.homeManager.develop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                zola
                vscode-langservers-extracted # HTML/CSS langserv
                prettierd
            ];
        };
}
