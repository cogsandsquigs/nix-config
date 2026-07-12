{ pkgs, ... }: {
    home.packages = with pkgs; [
        vscode-langservers-extracted # JSON langserv
        jsonnet-language-server
    ];
}
