{ ... }: {
  flake.modules.homeManager.dev.lang = { pkgs, ... }: {
    home.packages = with pkgs; [ docker-compose-language-service ];
  };
}
