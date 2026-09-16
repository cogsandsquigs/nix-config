{
    home =
        {
            lib,
            config,
            options,
            tools,
            ...
        }:
        let
            floating_pane_size_percent = 80;

            # A centred Zellij floating pane, `floating_pane_size_percent` of the screen each way. The
            # trailing `\` on every line is required: `:sh` is a shell run.
            #
            # `> /dev/null` swallows the pane ID `zellij run` prints -- helix shows it as hover-text that
            # needs an <ESC> to dismiss. Do not drop it.
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
        in
        {
            config = lib.mkIf config.my.user.dev.editors.helix.enable {
                # The keybinds below shell out to zellij and yazi, which `cli.utils` installs -- so
                # depend on that feature rather than installing a second copy of each here. helix
                # itself comes from `programs.helix` below.
                assertions = [
                    (tools.opt.dependsOn {
                        feature = options.my.user.dev.editors.helix.enable;
                        dependency = options.my.user.cli.utils.enable;
                        because = "the space-mode keybinds open zellij floating panes and the yazi file picker";
                    })
                ];

                programs.helix = {
                    enable = true;
                    defaultEditor = true;

                    # NOTE: See ./lsp.nix for LSP definitions &etc.

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

                                                # zellij reports 0x0 for a new pane's first ~25ms, and yazi exits rather than
                                                # wait for a real size. Block until the pty has one, and pass it on as well.
                                                for _ in {1..100}; do
                                                	read -r rows cols < <(stty size 2>/dev/null)
                                                	((cols > 0)) && break
                                                	sleep 0.005
                                                done
                                                export LINES=''${rows:-24} COLUMNS=''${cols:-80}

                                                # yazi sizes the terminal by ioctl on its stdout, and exits if that fails. A
                                                # command substitution makes stdout a pipe, so stdout stays on the tty and the
                                                # chosen path comes back on fd 3 instead.
                                                path=$(yazi "$1" --chooser-file=/dev/fd/3 3>&1 1>/dev/tty)

                                                # Temporary: hold the pane open when yazi fails, so its message survives
                                                # `--close-on-exit`.
                                                code=$?
                                                if ((code != 0)); then
                                                	read -rsn1 -p "picker failed ($code) -- press any key"
                                                fi

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
                                "Cmd-[" = "unindent"; # lib.mkIf stdenv.hostPlatform.isDarwin "unindent";
                                "Cmd-]" = "indent"; # lib.mkIf stdenv.hostPlatform.isDarwin "indent";
                            };
                        };

                        editor = {
                            true-color = true; # Force true-color (e.g. ssh)
                            # rainbow-brackets = true; # Rainbow-colored brackets NOTE: uncomment on next major (?) release, not included yet!
                            mouse = true; # Allow use of the mouse

                            rulers = [ 100 ]; # Vertical line columns
                            text-width = 100;

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
        };
}
