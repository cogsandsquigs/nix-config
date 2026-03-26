# Language configurations for the editor.
{ ... }:
{
    flake.modules.homeManager.editor =
        { ... }:
        {
            programs.helix = {
                # Language configurations for each language.
                # NOTE: This is the Nix equivalent to helix's `languages.toml` file
                # TODO: use imports from language spec to be editor-independent
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
                            config.haskell = {
                                formattingProvider = "fourmolu";

                                plugin = {
                                    fourmolu.config.external = true;
                                    hlint.diagnosticsOn = false; # Fixes https://github.com/haskell/haskell-language-server/issues/4674 until GHC fixed
                                    rename.config.crossModule = true; # Fixes https://github.com/haskell/haskell-language-server/issues/3571
                                };
                            };

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

                        # Python language server(s):

                        # Linter and formatter, from Astral.sh
                        ruff = {
                            command = "ruff";
                            args = [ "server" ];
                        };

                        # More advanced server, from Astral.sh (makers of Ruff)
                        ty = {
                            command = "ty";
                            args = [ "server" ];
                            config.ty = {
                                # Settings...
                            };
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
                                    # Actual formatting arguments
                                    "--column-limit=100"
                                    "--comma-style=trailing"
                                    "--function-arrows=leading"
                                    "--haddock-style=single-line"
                                    "--haddock-style-module=single-line"
                                    "--if-style=hanging"
                                    "--import-export-style=diff-friendly"
                                    "--indentation=4"
                                    "--indent-wheres=true"
                                    "--in-style=left-align"
                                    "--let-style=mixed"
                                    # "--record-style=knr" # Unreleased as of 2025-11-30!
                                    "--single-constraint-parens=always"
                                    "--single-deriving-parens=always"
                                    "--sort-constraints=true"
                                    "--sort-derived-classes=true"
                                    "--sort-deriving-clauses=true"
                                    "--trailing-section-operators=false"
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
                            language-servers = [
                                "ty"
                                "ruff"
                            ];
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
                                            lineWidth = 100;
                                            # markdown config goes here
                                            markdown = {
                                                lineWidth = 100;
                                            };
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
