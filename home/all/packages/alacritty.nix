{ pkgs, ... }:
{
    home.packages = with pkgs; [ alacritty ];

    programs.alacritty = {
        enable = true;
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
                builtin_box_drawing = false;
            };

            cursor = {
                style = {
                    shape = "Beam";
                    blinking = "Never";
                };
            };

            terminal = {
                osc52 = "CopyPaste";
            };

            mouse = {
                hide_when_typing = true;
            };
        };
        theme = "catppuccin_mocha";
    };
}
