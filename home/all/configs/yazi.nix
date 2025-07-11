{ pkgs, ... }:

{
    programs.yazi = {
        enable = true;
        package = pkgs.yazi;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;

        settings = {
            mgr = { };
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

        theme = {
            flavor = {
                dark = "catppuccin-mocha";
            };

            # Disable some annoying UI components:
            # That top line showing path. Since I use zellij, it's redundant!
            mgr.cwd = {
                hidden = false;
            };

        };
    };
}
