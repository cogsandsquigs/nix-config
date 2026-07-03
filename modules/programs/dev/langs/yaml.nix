{ ... }: {
    flake.modules.homeManager.dev.langs = { pkgs, ... }: {
        home.packages = with pkgs; [ yaml-language-server ];
    };
}
