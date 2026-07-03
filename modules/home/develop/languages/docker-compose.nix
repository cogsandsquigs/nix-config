{ ... }: {
    flake.modules.homeManager.develop = { pkgs, ... }: {
        home.packages = with pkgs; [ docker-compose-language-service ];
    };
}
