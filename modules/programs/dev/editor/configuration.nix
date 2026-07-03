{ inputs, ... }: {

    flake.modules.homeManager.dev.editor =
        { pkgs, ... }:
        let
            floating_pane_size_percent = 80;

            # Opens a Zellij floating pane of height and width
            # `floating_pane_size_percent` percent of the screen.
            # NOTE: Requires Zellij to be installed and configured.
            make_zellij_floating_pane =
                cmd:
                ":sh zellij run --close-on-exit --height ${toString floating_pane_size_percent}%% --width ${toString floating_pane_size_percent}%% --floating -x ${
                    toString ((100 - floating_pane_size_percent) / 2)
                }%% -y ${toString ((100 - floating_pane_size_percent) / 2)}%% -- ${cmd}";
        in
        {
            imports = with inputs.self.modules.homeManager; [
                utils.zellij
                utils.yazi
            ];

            home.packages = with pkgs; [ helix ];

            programs.helix = {
                enable = true;
                defaultEditor = true;

                # General settings
                # See: https://docs.helix-editor.com/configuration.html
                settings = {
                    theme = "catppuccin_mocha";

                    keys = {
                        # Keys in normal-mode (not highlighting/selecting or inserting text).
                        normal = {
                            # Keys in space-mode (after pressing leader/space)
                            # See: https://github.com/helix-editor/helix/issues/2841
                            space = {
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
                                f =
                                    let
                                        # Script to use Yazi as a file picker for helix.
                                        # NOTE: Assumes that helix is the previously-selected (I think?) or only pane!
                                        yazi_picker_script = builtins.toFile "yazi-picker.sh" ''
                                            #!/usr/bin/env bash

                                            path=$(yazi "$1" --chooser-file=/dev/stdout)

                                            # If `paths` is not empty, open it.
                                            if [[ -n "$path" ]]; then
                                            	zellij action toggle-floating-panes
                                            	zellij action write 27 # send <Escape> key
                                            	zellij action write-chars ":open '$path'"
                                            	zellij action write 13 # send <Enter> key
                                            # Otherwise, just close the pane
                                            else
                                            	zellij action toggle-floating-panes
                                            fi
                                        '';
                                    in
                                    make_zellij_floating_pane "bash ${yazi_picker_script} %{buffer_name}";
                            };

                            "[" = "unindent";
                            "]" = "indent";
                        };

                        # Keys in inserting mode (adding text)
                        insert = {
                            "C-[" = "unindent";
                            "C-]" = "indent";
                            "Cmd-[" = "unindent"; # lib.mkIf stdenv.isDarwin "unindent";
                            "Cmd-]" = "indent"; # lib.mkIf stdenv.isDarwin "indent";
                        };
                    };

                    editor = {
                        # rainbow-brackets = true; # Rainbow-colored brackets NOTE: uncomment on next major (?) release, not included yet!
                        mouse = true; # Allow use of the mouse

                        rulers = [ 100 ]; # Vertical line columns

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
            };
        };
}
