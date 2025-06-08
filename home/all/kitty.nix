{pkgs, ...}: {
    programs.kitty = {
        enable = true;

        darwinLaunchOptions = ["--start-as fullscreen"];

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

            # Font fixes
            "modify_font cell_width" = "+0px";
            "modify_font cell_height" = "+0px";
        };
    };
}
