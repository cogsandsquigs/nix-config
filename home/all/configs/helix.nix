{pkgs, ...}: {
    programs.helix = {
        enable = true;
        package = pkgs.helix;

        # General settings
        # See: https://docs.helix-editor.com/configuration.html
        settings = {
            theme = "catppuccin_mocha";

            keys.normal = {
                # Thx to this article: https://dev.to/rajasegar/helix-tmux-and-lazygit-7nj
                "g" = ":sh tmux popup -d \"#{pane_current_path}\" -xC -yC -w80% -h80% -E lazygit";
            };

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
                    render = {
                        tab = "all";
                        space = "all";
                        nbsp = "none";
                        nnbsp = "none";
                        newline = "none";
                    };

                    characters = {
                        tab = "→";
                        tabpad = " "; # Tabs will look like this: "→   "
                        space = "·";
                    };
                };

                indent-guides = {
                    render = true;
                    character = "│";
                    skip-levels = 1;
                };

                inline-diagnostics = {
                    cursor-line = "hint";
                    other-lines = "hint";
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
