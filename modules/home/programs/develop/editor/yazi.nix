{ ... }:
{
    flake.modules.homeManager.yazi =
        { pkgs, ... }:
        {
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
                            rev = "9511cb09cadcbf57e39a46b06a52d00957177175";
                            hash = "sha256-hEnrvfJwCAgM12QwPmjHEwF5xNrwqZH1fTIb/QG0NFI=";
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
