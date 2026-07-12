# Language configurations for the editor.
{ lib, config, ... }: {
    config = lib.mkIf config.my.user.dev.editors.helix.enable {
        programs.helix = {
            # Language configurations for each language.
            # NOTE: This is the Nix equivalent to helix's `languages.toml` file
            # TODO: use imports from language spec to be editor-independent
            languages = {
                # Language-server settings.
                language-server = {
                    ## HTML ##

                    vscode-html-language-server = {
                        command = "vscode-html-language-server";
                        args = [ "--stdio" ];
                    };

                    ## CSS ##

                    vscode-css-language-server = {
                        command = "vscode-css-language-server";
                        args = [ "--stdio" ];
                    };

                    ## JSON ##

                    vscode-json-language-server = {
                        command = "vscode-json-language-server";
                        args = [ "--stdio" ];
                    };

                    ## YAML ##
                    yaml-language-server = {
                        command = "yaml-language-server";
                        args = [ "--stdio" ];
                    };

                    ## LATEX ##

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
                        language-servers = [ "vscode-html-language-server" ];
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
                        name = "css";
                        language-servers = [ "vscode-css-language-server" ];
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
                        name = "scss";
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
                        name = "jsonc";
                        language-servers = [ "vscode-json-language-server" ];
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
                        language-servers = [ "vscode-json-language-server" ];
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
                        name = "yaml";
                        language-servers = [ "yaml-language-server" ];
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
                        name = "docker-compose";
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
                                        lineWidth = 100;

                                        # markdown config goes here
                                        markdown = {
                                            lineWidth = 100;
                                            textWrap = "always";
                                        };
                                        plugins = [ "https://plugins.dprint.dev/markdown-0.22.0.wasm" ];
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

                    {
                        name = "scala";
                        auto-format = true;
                        # NOTE: The default language server is `metals`, which automatically formats
                        # code as well --- no need to specify a formatter. It is faster than calling
                        # `scalafmt` from the command-line as well. Any formatting options are specified
                        # in a `.scalafmt.conf` file (HOCOL syntax) --- so no need to pass cmd-line
                        # options for it unless wanting to configure LSP itself.
                    }
                ];
            };
        };
    };
}
