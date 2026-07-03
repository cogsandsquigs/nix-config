{ ... }: {
    flake.modules.homeManager.dev.lang = { pkgs, ... }: {
        home.packages = with pkgs; [
            nodejs
            bun

            typescript-language-server # JS/TS langserv
            prettierd
        ];
    };
}
