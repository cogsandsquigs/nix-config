{ pkgs, ... }:
{
    programs.alacritty = {
        enable = true;
        package = pkgs.alacritty;
        settings = {
            general = {
                live_config_reload = true;
            };

            env = {
                TERM = "xterm-256color";
            };

            window = {
                opacity = 0.8;
                blur = true;
                startup_mode = "Fullscreen";
            };

            font = {
                normal = {
                    family = "FiraCode Nerd Font Mono";
                    style = "Regular";
                };
                size = 13.0;
            };

            cursor = {
                style = {
                    shape = "Beam";
                    blinking = "Never";
                };
            };
        };
        theme = "catppuccin_mocha";
    };
}
