# General CLI utilities.
{
    home =
        {
            pkgs,
            lib,
            config,
            tools,
            ...
        }:
        {
            options.my.user.cli.utils.enable =
                tools.opt.mkEnabled "CLI utilities (gpg, yazi, zellij, fzf, ripgrep, eza, ...)";

            config = lib.mkIf config.my.user.cli.utils.enable {
                # Only what nothing else installs: a `programs.<x>.enable` below already brings its own
                # package, and `lazygit` comes with my.user.cli.git.
                home.packages = with pkgs; [
                    fzf
                    ripgrep
                    jq
                    just
                    tree
                    magic-wormhole
                    fontconfig
                    inetutils
                    dust
                    fastfetch
                    asciinema
                ];

                # `enable` is what makes any of this apply -- the settings alone are inert. It aliases
                # `eza` to itself plus these flags and points `ls`/`ll`/`la`/`lt`/`lla` at that, so the
                # flags reach every one of them through a single alias.
                programs.eza = {
                    enable = true;
                    icons = "auto"; # a bool here is deprecated upstream
                    colors = "auto";
                    git = true;
                };

                programs.zoxide = {
                    enable = true;
                    enableZshIntegration = true;
                    enableFishIntegration = true;
                };

                programs.bat = {
                    enable = true;
                    themes = {
                        dracula = {
                            src = pkgs.fetchFromGitHub {
                                owner = "catppuccin";
                                repo = "bat"; # Bat uses sublime syntax for its themes
                                rev = "6810349b28055dce54076712fc05fc68da4b8ec0";
                                sha256 = "sha256-lJapSgRVENTrbmpVyn+UQabC9fpV1G1e+CdlJ090uvg=";
                            };
                            file = "themes/Catppuccin Mocha.tmTheme";
                        };
                    };
                };
            };
        };
}
