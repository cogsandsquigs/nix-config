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
                home.packages = with pkgs; [
                    fzf
                    ripgrep
                    jq
                    just
                    tree
                    magic-wormhole
                    fontconfig
                    inetutils
                    eza
                    dust
                    bat
                    zoxide
                    lazygit
                    fastfetch
                ];

                programs.eza = {
                    colors = "auto";
                    git = true;
                    icons = true;
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
