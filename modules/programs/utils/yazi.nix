{ ... }: {
    flake.modules.homeManager.utils.yazi = { pkgs, ... }: {
        programs.yazi = {
            enable = true; # NOTE: For some reason this causes a mismatched hash. when fix?
            enableBashIntegration = true;
            enableFishIntegration = true;
            enableZshIntegration = true;

            # Legacy was `yy`, new default will be `y`. Setting as this to adopt the new default
            # sooner.
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
                        rev = "54ab389e4deb3d1bc1d8de18d99e825962a55da1";
                        hash = "sha256-46x4K4dx4rlU108SXhctJOeGlO/W57Pnofb914Sa4vA=";
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
    };
}
