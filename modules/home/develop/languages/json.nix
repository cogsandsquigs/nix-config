{ ... }:
{
    flake.modules.homeManager.develop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                vscode-langservers-extracted
                jsonnet-language-server
            ];
        };
}
