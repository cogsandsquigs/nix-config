{ pkgs, lib, ... }:
let
    inherit (pkgs) stdenv;
    floating_pane_size_percent = 80;

    # Opens a Zellij floating pane of height and width
    # `floating_pane_size_percent` percent of the screen.
    # NOTE: Requires Zellij to be installed and configured.
    make_zellij_floating_pane =
        cmd:
        ":sh zellij run --close-on-exit --height ${builtins.toString floating_pane_size_percent}%% --width ${builtins.toString floating_pane_size_percent}%% --floating -x ${
            builtins.toString ((100 - floating_pane_size_percent) / 2)
        }%% -y ${
            builtins.toString ((100 - floating_pane_size_percent) / 2)
        }%% -- ${cmd}";

in
{
    home.packages = with pkgs; [ helix ];

    programs.helix = {
        enable = true;
        package = pkgs.helix;

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

                                    paths=$(yazi "$2" --chooser-file=/dev/stdout | while read -r; do printf "%q " "$REPLY"; done)

                                    if [[ -n "$paths" ]]; then
                                    	zellij action toggle-floating-panes
                                    	zellij action write 27 # send <Escape> key
                                    	zellij action write-chars ":$1 $paths"
                                    	zellij action write 13 # send <Enter> key
                                    else
                                    	zellij action toggle-floating-panes
                                    fi
                                '';
                            in
                            make_zellij_floating_pane "bash ${yazi_picker_script} open %{buffer_name}";
                    };

                    "[" = "unindent";
                    "]" = "indent";
                };

                # Keys in inserting mode (adding text)
                insert = {
                    "C-[" = "unindent";
                    "C-]" = "indent";
                    "Cmd-[" = lib.mkIf stdenv.isDarwin "unindent";
                    "Cmd-]" = lib.mkIf stdenv.isDarwin "indent";
                };
            };

            editor = {
                # rainbow-brackets = true; # Rainbow-colored brackets NOTE: uncomment on next major (?) release, not included yet!
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

                # Haskell language server
                haskell-language-server = {
                    command = "haskell-language-server-wrapper";
                    args = [ "--lsp" ];
                    config.haskell-language-server = { };

                };

                # Nix language server
                nil = {
                    command = "nil";
                    args = [ "--stdio" ];
                    config.nil = {
                        # // Auto-archiving behavior which may use network.
                        # //
                        # // - null: Ask every time.
                        # // - true: Automatically run `nix flake archive` when necessary.
                        # // - false: Do not archive. Only load inputs that are already on disk.
                        # // Type: null | boolean
                        # // Example: true
                        flake.autoArchive = true;
                    };
                };

                # Python language server
                ruff = {
                    command = "ruff";
                    args = [ "server" ];
                };

                # LaTeX language server
                # See: https://github.com/helix-editor/helix/issues/340#issuecomment-1167200354
                texlab = {
                    config.texlab = {
                        build = {
                            onSave = true;
                            forwardSearchAfter = true;

                        };

                        forwardSearch = {
                            executable = "???"; # TODO: This!
                            args = [ ]; # TODO: This! (synctex args)
                        };

                        chktex.onEdit = true;
                    };

                };
            };

            # Language configurations for each language.
            language = [
                {
                    name = "c";
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                }
                {
                    name = "cpp";
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                }
                {
                    name = "bash";
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                    file-types = [
                        "bash"
                        "sh"
                    ];
                    formatter = {
                        command = "shfmt";
                        args = [
                            "--indent=4"
                            "--binary-next-line"
                            "--case-indent"
                            "--space-redirects"
                            "-"
                        ];
                    };

                }
                {
                    name = "html";
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                    formatter = {
                        command = "prettierd";
                        args = [ "%{buffer_name}" ];
                    };
                }
                {
                    name = "svelte";
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                    formatter = {
                        command = "prettierd";
                        args = [ "%{buffer_name}" ];
                    };
                }
                {
                    name = "javascript";
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                    formatter = {
                        command = "prettierd";
                        args = [ "%{buffer_name}" ];
                    };
                }
                {
                    name = "typescript";
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                    formatter = {
                        command = "prettierd";
                        args = [ "%{buffer_name}" ];
                    };
                }
                {
                    name = "json";
                    file-types = [
                        "json"
                        "prettierrc"
                    ];
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                    formatter = {
                        command = "prettierd";
                        args = [ "%{buffer_name}" ];
                    };
                }
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
                    name = "haskell";
                    language-servers = [ "haskell-language-server" ];
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                    roots = [
                        "Setup.hs"
                        "stack.yaml"
                        "*.cabal"
                        "*.hs"
                        "*.lhs"
                    ];
                    formatter = {
                        command = "fourmolu";
                        args = [
                            "--stdin-input-file=%{buffer_name}"
                            "--indent-wheres=true"
                            "--haddock-style=single-line"
                            "--haddock-style-module=single-line"
                            "--in-style=left-align"
                            "--let-style=mixed"
                            "--comma-style=trailing"
                        ];
                    };

                }

                {
                    name = "toml";
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                    formatter = {
                        command = "taplo";
                        args = [
                            "fmt"
                            "-o=align_entries=true"
                            "-o=align-comments"
                            "-o=allowed_blank_lines=1"
                            "-o=indent_entries=true"
                            "-o=indent_tables=true"
                            "-o=indent_string=    "
                            "-o=reorder_arrays=false"
                            "-o=reorder_keys=true"
                            "-"
                        ];
                    };
                }

                {
                    name = "pest";
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                    # NOTE: No need to configure, pest-language-server is default
                    # NOTE: LSP comes with formatter, no need for formatter!
                    language-servers = [ "pest-language-server" ];
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
                    # This is gonna be a biiit weird
                    # See: https://stackoverflow.com/questions/77876253/sort-imports-alphabetically-with-ruff
                    # And: https://github.com/helix-editor/helix/discussions/7749
                    formatter = {
                        command = "bash";
                        args = [
                            "-c"
                            "ruff check --select I --fix - | ruff format -"
                        ];
                    };
                }

                {
                    name = "markdown";
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                    formatter =
                        let
                            # NOTE: Schema for configuration is here: https://dprint.dev/config/
                            dprint-config = builtins.toFile "dprint.json" (
                                builtins.toJSON {
                                    lineWidth = 80;
                                    # markdown config goes here
                                    markdown = { };
                                    plugins = [
                                        "https://plugins.dprint.dev/markdown-0.19.0.wasm"
                                        "https://plugins.dprint.dev/typescript-0.95.11.wasm"
                                        "https://plugins.dprint.dev/json-0.20.0.wasm"
                                    ];
                                }
                            );
                        in
                        {
                            command = "dprint";
                            args = [
                                "fmt"
                                "--config=${dprint-config}"
                                "--stdin"
                                "%{buffer_name}"
                            ];

                        };
                }

                {
                    name = "latex";
                    auto-format = true;
                    indent = {
                        tab-width = 4;
                        unit = "    ";
                    };
                    language-servers = [ "texlab" ];
                    formatter = {
                        command = "latexindent";
                        args = [ "-" ];
                    };
                }
            ];
        };
    };
}
