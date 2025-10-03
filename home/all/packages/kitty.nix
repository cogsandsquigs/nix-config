{ pkgs, ... }:
{
    home.packages = with pkgs; [ kitty ];

    programs.kitty = {
        enable = true;

        darwinLaunchOptions = [ "--start-as fullscreen" ];

        font = {
            name = "FiraCode Nerd Font Mono";
            package = pkgs.nerd-fonts.fira-code;
            size = 13;
        };

        keybindings = {
            # Linux keybinds
            "super+d" = "new_window";
            "super+]" = "next_window";
            "super+[" = "previous_window";

            # MacOS keybinds
            "cmd+d" = "new_window";
            "cmd+]" = "next_window";
            "cmd+[" = "previous_window";
        };

        themeFile = "Catppuccin-Mocha";

        settings = {
            cursor_shape = "beam"; # Make cursor look like |
            enabled_layouts = "tall:bias=50;full_size=1;mirrored=false"; # Enable tall layout priority w/ multiple terminals

            # Make windows close when OS asks them to close, even if running a process.
            # NOTE: We do this because we use zellij (terminal multiplexer) and so it's
            # kinda pointless to ask anyways.
            confirm_os_window_close = 0;

            # Font fixes
            "modify_font cell_width" = "+0px";
            "modify_font cell_height" = "+0px";
        };
    };
}
