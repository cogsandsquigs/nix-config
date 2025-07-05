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
                gutters = ["diagnostics" "spacer" "line-numbers" "spacer" "diff"];

                statusline = {
                    left = ["mode" "version-control"];
                    center = ["file-name" "file-modification-indicator" "diagnostics"];
                    right = ["file-type" "file-encoding" "spinner" "register"];

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

                whitespace = {
                    render = "all";

                    characters = {
                        tab = "→";
                        tabpad = " "; # Tabs will look like this: "→   "
                        space = "·";
                        nbsp = "⍽";
                        nnbsp = "␣";
                    };
                };

                indent-guides = {
                    render = true;
                    character = "│";
                    skip-levels = 1;
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
