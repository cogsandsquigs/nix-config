{pkgs, ...}: {
    programs.helix = {
        enable = true;
        package = pkgs.helix;

        # General settings
        # See: https://docs.helix-editor.com/configuration.html
        settings = {
            theme = "catppuccin_mocha";

            # Keys in normal-mode (not highlighting/selecting or inserting
            # text).
            keys.normal = {
                # Keys in space-mode (after pressing leader/space)
                # See: https://github.com/helix-editor/helix/issues/2841
                space = let
                    floating_pane_size_percent = 80;
                    side_pane_size_percent = 30;

                    # Opens a Zellij floating pane of height and width
                    # `floating_pane_size_percent` percent of the screen.
                    # NOTE: Requires Zellij to be installed and configured.
                    make_zellij_floating_pane = cmd: [
                        ":sh zellij run --close-on-exit --height ${builtins.toString floating_pane_size_percent}% --width ${builtins.toString floating_pane_size_percent}% --floating -x ${builtins.toString ((100 - floating_pane_size_percent) / 2)}% -y ${builtins.toString ((100 - floating_pane_size_percent) / 2)}% -- ${cmd}"
                    ];
                in {
                    # Opens a lazygit floating pane via `space-l-g`.
                    l.g = make_zellij_floating_pane "lazygit";

                    # Opens a terminal-interface floating pane via `space-t`.
                    t = make_zellij_floating_pane "$SHELL";

                    # Opens a file picker using `nnn` via via `space-f`.
                    # NOTE: Overrides the default helix file picker!
                    # f = make_zellij_floating_pane "nnn -d";
                };
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
                        space = " "; # NOTE: only doing this b/c then spaces btwn words get annoying characters in them
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
            language-server = {
                rust-analyzer = {
                    command = "rust-analyzer";

                    # See: https://rust-analyzer.github.io/book/configuration
                    config.rust-analyzer = {
                        check.command = "clippy";
                        procMacro.enable = true;
                        cargo.buildScripts.enable = true;
                    };
                };
            };

            # Language configurations for each language.
            language = [
                {
                    name = "rust";
                    language-servers = ["rust-analyzer"];
                    formatter = {
                        command = "rustfmt";
                        args = [];
                    };
                }
            ];
        };
    };
}
