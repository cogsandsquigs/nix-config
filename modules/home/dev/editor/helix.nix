{
    pkgs,
    lib,
    config,
    ...
}:
let
    # Translate lang specs → Helix language config
    specs = config.my.user.dev.langs.specs;

    toCmd = list: {
        command = lib.head list;
        args = lib.tail list;
    };

    toLsp =
        lsp:
        lib.nameValuePair lsp.name (
            {
                command = lib.head lsp.cmd;
            }
            // lib.optionalAttrs (builtins.length lsp.cmd > 1) { args = lib.tail lsp.cmd; }
            // lib.optionalAttrs (lsp.config != { }) { inherit (lsp) config; }
        );

    toLang =
        spec: langName:
        {
            name = langName;
        }
        // {
            auto-format = true;
            indent = {
                tab-width = 4;
                unit = "    ";
            };
        }
        // lib.optionalAttrs (spec.lsp != [ ]) { language-servers = map (l: l.name) spec.lsp; }
        // lib.optionalAttrs (spec.fmt != null) { formatter = toCmd spec.fmt; }
        // lib.optionalAttrs (spec.file-types ? ${langName}) { file-types = spec.file-types.${langName}; }
        // lib.optionalAttrs (spec.roots ? ${langName}) { roots = spec.roots.${langName}; };

    specLsps = lib.listToAttrs (lib.concatMap (s: map toLsp s.lsp) specs);
    specLangs = lib.concatMap (s: map (toLang s) s.lang) specs;

    floating_pane_size_percent = 80;

    # Opens a Zellij floating pane of height and width
    # `floating_pane_size_percent` percent of the screen.
    # NOTE: Requires Zellij to be installed and configured.
    # NOTE: The `\` is required at the end of each line because `:sh` is fundamentally a shell run.
    make_zellij_floating_pane = cmd: ''
        :sh zellij run --close-on-exit \
                       --height ${toString floating_pane_size_percent}%% \
                       --width ${toString floating_pane_size_percent}%% \
                       --floating \
                       -x ${toString ((100 - floating_pane_size_percent) / 2)}%% \
                       -y ${toString ((100 - floating_pane_size_percent) / 2)}%% \
                       -- ${cmd} \
                       > /dev/null
    '';

    # NOTE: About the piping to /dev/null...
    #
    # If you use `zellij run`, it returns the name of the pane's ID. This is something like
    # `terminal_<#>`. Now, on helix, this results in the cursor displaying hover-text with that ID.
    # This is annoying, and requires an `<ESC>` key-hit to go away. So, by piping the output to
    # `/dev/null`, we get rid of that hover-text.
    #
    # This didn't use to be the case, and at some point along the way zellij made `zellij run`
    # return IDs. This confused me for the longest time.
    #
    # Now you know, future me! So, uh, don't delete that `> /dev/null`, unless you want hover-text
    # of the new pane's ID.
in
{
    config = lib.mkIf config.my.user.dev.editors.helix.enable {
        home.packages = with pkgs; [
            helix
            zellij # Requirement for the editor functionality...
            yazi # Requirement for the editor functionality...
        ];

        programs.helix = {
            enable = true;
            defaultEditor = true;

            # General settings
            # See: https://docs.helix-editor.com/configuration.html
            languages = {
                language-server = specLsps;
                language = specLangs;
            };

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
