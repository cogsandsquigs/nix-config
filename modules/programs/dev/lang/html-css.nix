{ ... }: {
    flake.modules.homeManager.dev.lang = { pkgs, ... }: {
        home.packages = with pkgs; [
            zola
            vscode-langservers-extracted # HTML/CSS langserv
            prettierd
        ];
    };
}
