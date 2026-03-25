{ pkgs, ... }:

{
    home.packages = with pkgs; [ yazi ];

    programs.yazi = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;

        # Legacy was `yy`, new default will be `y`. Setting as this to adopt the new default sooner.
        shellWrapperName = "y";

        settings = {
            mgr = {
                show_hidden = true;
            };
        };

        flavors =
            let
                yazi-flavors = pkgs.fetchFromGitHub {
                    owner = "yazi-rs";
                    repo = "flavors";
                    rev = "ffe6e3a16c5c51d7e2dedacf8de662fe2413f73a";
                    hash = "sha256-RtunaCs1RUfzjefFLFu5qLRASbyk5RUILWTdavThRkc=";
                };
            in
            {
                catppuccin-mocha = "${yazi-flavors}/catppuccin-mocha.yazi";
            };

        theme = {
            flavor = {
                dark = "catppuccin-mocha";
                light = "catppuccin-mocha";
            };
        };
    };
}
