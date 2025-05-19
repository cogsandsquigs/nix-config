return {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = function()
        local conform = require("conform")

        conform.setup({
            -- Configure log level
            log_level = vim.log.levels.DEBUG,

            formatters_by_ft = {
                astro = { "prettierd" },
                c = { "clang-format" },
                cpp = { "clang-format" },
                cmake = { "gersemi" },
                css = { "prettierd" },
                jinja = { "djlint" },
                glsl = { lsp_format = "first" },
                graphql = { "prettierd" },
                haskell = { "fourmolu" },
                h = { "clang-format" },
                hpp = { "clang-format" },
                html = { "prettierd" },
                htmldjango = { "djlint" },
                javascript = { "prettierd" },
                javascriptreact = { "prettierd" },
                json = { "prettierd" },
                jsonc = { "prettierd" },
                kotlin = { "ktfmt" },
                latex = { "latexindent" },
                liquid = { "prettierd" },
                lua = { "stylua" },
                markdown = { "prettierd" },
                mdx = { "prettierd" },
                nix = { "alejandra" },
                -- pest = { "pestfmt" }, -- NOTE: Disabling b/c formatter SUCKS
                python = { "isort", "black" },
                rust = { "rustfmt" },
                sass = { "prettierd" },
                scss = { "prettierd" },
                sql = { "sqlfluff" },
                svelte = { "prettierd" },
                tex = { "latexindent" },
                tera = { "djlint" },
                toml = { "taplo" },
                typescript = { "prettierd" },
                typescriptreact = { "prettierd" },
                yaml = { "prettierd" },
            },

            format_on_save = {
                lsp_fallback = true,
                async = true,
                timeout_ms = 1000,
            },

            -- Configure formatters
            formatters = {
                alejandra = {
                    command = "alejandra",
                },

                ["clang-format"] = {
                    command = "clang-format",
                    args = {
                        "--style={BasedOnStyle: LLVM, UseTab: Never, IndentWidth: 4, TabWidth: 4, BreakBeforeBraces: Attach, AllowShortIfStatementsOnASingleLine: AllIfsAndElse, IndentCaseLabels: true, ColumnLimit: 80, AccessModifierOffset: -4, NamespaceIndentation: All, FixNamespaceComments: false }",
                    },
                },

                djlint = {
                    command = "djlint",
                    args = {
                        "--reformat",
                        "--indent=4",
                        "--indent-css=4",
                        "--indent-js=4",
                        "--format-css",
                        "--format-js",
                        "--max-blank-lines=1",
                        "--profile='jinja'",
                        "--quiet",
                        "--use-gitignore",
                        "-",
                    },
                },

                fourmolu = {
                    args = {
                        "--stdin-input-file",
                        "$FILENAME",
                        "--indent-wheres=true",
                        "--haddock-style=single-line",
                        "--haddock-style-module=single-line",
                        "--in-style=left-align",
                        "--let-style=mixed",
                        "--comma-style=trailing",
                    },
                },

                latexindent = {
                    args = {
                        '-y="defaultIndent:"    ""',
                        "-",
                    },
                },

                pestfmt = {
                    command = "pestfmt",
                    args = {
                        "--stdin",
                    },
                },

                taplo = {
                    args = {
                        "format",

                        -- CONFIG BEGINS HERE
                        -- All options most be prefaced by "--option" or "-o", and then another (separate)
                        -- string defining the argument.

                        "-o",
                        "align_entries=true",
                        "-o",
                        "align-comments",
                        "-o",
                        "allowed_blank_lines=1",
                        "-o",
                        "indent_entries=true",
                        "-o",
                        "indent_tables=true",
                        "-o",
                        "indent_string=    ",
                        "-o",
                        "reorder_arrays",
                        "-o",
                        "reorder_keys",

                        -- CONFIG ENDS HERE

                        -- This tells Taplo to use stdin as input, and write to stdout the formatted file. Since that is how
                        -- Conform expects formatters to work, we need to make that happen.
                        "-",
                    },
                },
            },
        })

        vim.keymap.set({ "n", "v" }, "<leader>mp", function()
            conform.format({
                lsp_fallback = true,
                async = false,
                timeout_ms = 1000,
            })
        end, { desc = "Format file or range (in visual mode)" })
    end,
}
