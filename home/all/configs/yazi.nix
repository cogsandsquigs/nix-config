{ pkgs, ... }:
{
    programs.yazi = {
        enable = true;
        package = pkgs.yazi;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;

        theme = {
            flavor = {
                dark = "catppuccin-mocha";
            };
        };

        flavors =
            let
                yazi-flavors = pkgs.fetchFromGitHub {
                    owner = "yazi-rs";
                    repo = "flavors";
                    rev = "d3fd3a5d774b48b3f88845f4f0ae1b82f106d331";
                    hash = "sha256-RtunaCs1RUfzjefFLFu5qLRASbyk5RUILWTdavThRkc=";
                };
            in
            {
                catppuccin-mocha = "${yazi-flavors}/catppuccin-mocha.yazi";
            };
    };
}
