{pkgs, ...}: {
    programs.helix = {
        enable = true;
        package = pkgs.helix;

        # General settings
        # See: https://docs.helix-editor.com/configuration.html
        settings = {
            theme = "catppuccin_mocha";

            editor = {
                mouse = true; # Allow use of the mouse

                statusline = {
                    left = ["mode" "separator" "version-control"];
                    center = ["file-name" "separator" "file-modification-indicator" "separator" "diagnostics"];
                    right = ["file-type" "separator" "file-encoding" "separator" "spinner" "separator" "register"];

                    separator = "|";

                    mode.normal = "NORMAL";
                    mode.insert = "INSERT";
                    mode.select = "SELECT";
                };

                cursor-shape = {
                    insert = "bar";
                    normal = "block";
                    select = "underline";
                };
            };
        };

        # Language-specific settings
        # See: https://docs.helix-editor.com/languages.html
        languages = {
            # Language-server settings.
            language-server = {};

            # Language configurations for each language.
            language = [];
        };
    };
}
