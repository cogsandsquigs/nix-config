{ ... }: {
    flake.modules.homeManager.dev.langs = { pkgs, ... }: {
        home.packages = with pkgs; [
            pest-ide-tools # Installs pest LSP
        ];
    };
}
