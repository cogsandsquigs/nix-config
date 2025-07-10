{ pkgs, ... }:
{
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
                space =
                    let
                        floating_pane_size_percent = 80;

                        # Opens a Zellij floating pane of height and width
                        # `floating_pane_size_percent` percent of the screen.
                        # NOTE: Requires Zellij to be installed and configured.
                        make_zellij_floating_pane =
                            cmd:
                            ":sh zellij run --close-on-exit --height ${builtins.toString floating_pane_size_percent}% --width ${builtins.toString floating_pane_size_percent}% --floating -x ${
                                builtins.toString ((100 - floating_pane_size_percent) / 2)
                            }% -y ${builtins.toString ((100 - floating_pane_size_percent) / 2)}% -- ${cmd}";

                        # Script to use Yazi as a file picker for helix.
                        # NOTE: Assumes that helix is the previously-selected (I think?) or only pane!
                        yazi_picker_script = builtins.toFile "yazi-picker.sh" ''
                            #!/usr/bin/env bash

                            # NOTE: In the original script (see the file picker key), this took in `$2`
                            # since the 1st argument was either `open`, `hsplit`, or `vsplit`.
                            paths=$(yazi "$1" --chooser-file=/dev/stdout | while read -r; do printf "%q " "$REPLY"; done)

                            if [[ -n "$paths" ]]; then
                                zellij action toggle-floating-panes
                                zellij action write 27 # send <Escape> key
                                
                                # NOTE: In the original script (see the file picker key), this took
                                # in `$1` in place of `open` since the 1st argument was either `open`,
                                #  `hsplit`, or `vsplit`.
                                zellij action write-chars ":open $paths"
                                zellij action write 13 # send <Enter> key
                            else
                                zellij action toggle-floating-panes
                            fi
                        '';
                    in
                    {
                        # Opens a lazygit floating pane via `space-l-g`.
                        l.g = make_zellij_floating_pane "lazygit";

                        # Opens a terminal-interface floating pane via `space-t`.
                        t = make_zellij_floating_pane "$SHELL";

                        # Opens a file picker using `nnn` via via `space-f`.
                        # NOTE: Overrides the default helix file picker!
                        # See: https://yazi-rs.github.io/docs/tips/#helix-with-zellij
                        # NOTE: When Helix allows command expansion variables (see: https://github.com/helix-editor/helix/pull/12527)
                        # then we can pass 2nd argument as `%{buffer_name}`. For now, we pass `$(pwd)` to
                        # not upset `yazi`.
                        f = make_zellij_floating_pane "bash ${yazi_picker_script} $(pwd)";
                    };
            };

            editor = {
                mouse = true; # Allow use of the mouse
                gutters = [
                    "diagnostics"
                    "spacer"
                    "line-numbers"
                    "spacer"
                    "diff"
                ];
                auto-format = true;
                statusline = {
                    left = [
                        "mode"
                        "version-control"
                    ];
                    center = [
                        "file-name"
                        "file-modification-indicator"
                        "diagnostics"
                    ];
                    right = [
                        "file-type"
                        "file-encoding"
                        "spinner"
                        "register"
                    ];

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
                # Rust language server
                rust-analyzer = {
                    command = "rust-analyzer";

                    # See: https://rust-analyzer.github.io/book/configuration
                    config.rust-analyzer = {
                        check.command = "clippy";
                        procMacro.enable = true;
                        cargo.buildScripts.enable = true;
                    };
                };

                # Nix language server
                nil = {
                    command = "nil";
                    args = [ "--stdio" ];
                };

                # Python language server
                ruff = {
                    command = "ruff";
                    args = [ "server" ];
                };
            };

            # Language configurations for each language.
            language = [
                {
                    name = "rust";
                    language-servers = [ "rust-analyzer" ];
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                    formatter = {
                        command = "rustfmt";
                        args = [ ];
                    };
                }
                {
                    name = "nix";
                    language-servers = [ "nil" ];
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                    formatter = {
                        command = "nixfmt";
                        args = [
                            "--width=80"
                            "--indent=4"
                            "--quiet"
                            "--strict"
                        ];

                    };
                }

                {
                    name = "python";
                    language-servers = [ "ruff" ];
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                    formatter = {
                        command = "ruff";
                        args = [
                            "format"
                            "-"
                        ];
                    };
                }
            ];
        };
    };
}
