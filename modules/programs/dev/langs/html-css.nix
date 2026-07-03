{ ... }: {
    flake.modules.homeManager.dev.langs = { pkgs, ... }: {
        home.packages = with pkgs; [
            zola
            vscode-langservers-extracted # HTML/CSS langserv
            prettierd
        ];
    };
}
