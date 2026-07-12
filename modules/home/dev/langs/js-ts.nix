{ pkgs, ... }: {
    home.packages = with pkgs; [
        nodejs
        bun

        typescript-language-server # JS/TS langserv
        vscode-langservers-extracted # Contains ESLint language server
        prettierd
    ];
}
