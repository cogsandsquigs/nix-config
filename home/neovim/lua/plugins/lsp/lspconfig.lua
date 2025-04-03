return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            { "antosha417/nvim-lsp-file-operations", config = true },
            { "pest-parser/pest.vim" }, -- NOTE: For pest-language-server to work
        },
        config = function()
            -- import lspconfig plugin
            local lspconfig = require("lspconfig")

            -- import mason_lspconfig plugin
            local mason_lspconfig = require("mason-lspconfig")

            local keymap = vim.keymap -- for conciseness

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                callback = function(ev)
                    -- Buffer local mappings.
                    -- See `:help vim.lsp.*` for documentation on any of the below functions
                    local opts = { buffer = ev.buf, silent = true }

                    -- set keybinds
                    opts.desc = "Show LSP references"
                    keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

                    opts.desc = "Go to declaration"
                    keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

                    opts.desc = "Show LSP definitions"
                    keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

                    opts.desc = "Show LSP implementations"
                    keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

                    opts.desc = "Show LSP type definitions"
                    keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

                    opts.desc = "See available code actions"
                    keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

                    opts.desc = "Smart rename"
                    keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

                    opts.desc = "Show buffer diagnostics"
                    keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show	diagnostics for file

                    opts.desc = "Show line diagnostics"
                    keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

                    opts.desc = "Go to previous diagnostic"
                    keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

                    opts.desc = "Go to next diagnostic"
                    keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

                    opts.desc = "Show documentation for what is under cursor"
                    keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

                    opts.desc = "Restart LSP"
                    keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
                end,
            })

            -- used to enable autocompletion (assign to every lsp server config)
            local capabilities = require("blink.cmp").get_lsp_capabilities()

            -- Change the Diagnostic symbols in the sign column (gutter)
            -- (not in youtube nvim video)
            local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
            for type, icon in pairs(signs) do
                local hl = "DiagnosticSign" .. type
                vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
            end

            mason_lspconfig.setup_handlers({
                -- Default handler for installed servers
                function(server_name)
                    lspconfig[server_name].setup({
                        capabilities = capabilities,
                    })
                end,

                -- Custom handlers
                ["clangd"] = function()
                    lspconfig["clangd"].setup({
                        capabilities = capabilities,
                        command = {
                            "clangd",
                            "--background-index",
                            "-j=12",
                            --  "--query-driver=/usr/bin/**/clang-*,/bin/clang,/bin/clang++,/usr/bin/gcc,/usr/bin/g++",
                            "--clang-tidy",
                            "--clang-tidy-checks=*",
                            "--all-scopes-completion",
                            "--cross-file-rename",
                            "--completion-style=detailed",
                            "--header-insertion-decorators",
                            "--header-insertion=iwyu",
                            "--pch-storage=memory",
                        },
                        filetypes = {
                            "c",
                            "cpp",
                        },
                    })
                end,

                ["emmet_ls"] = function()
                    -- configure emmet language server
                    lspconfig["emmet_ls"].setup({
                        capabilities = capabilities,
                        filetypes = {
                            "html",
                            "typescriptreact",
                            "javascriptreact",
                            "css",
                            "sass",
                            "scss",
                            "less",
                            "svelte",
                        },
                    })
                end,

                ["eslint"] = function()
                    lspconfig["eslint"].setup({
                        capabilities = capabilities,
                        filetypes = {
                            "javascript",
                            "javascriptreact",
                            "typescript",
                            "typescriptreact",
                        },
                    })
                end,

                ["graphql"] = function()
                    -- configure graphql language server
                    lspconfig["graphql"].setup({
                        capabilities = capabilities,
                        filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
                    })
                end,

                ["hls"] = function()
                    lspconfig["hls"].setup({
                        capabilities = capabilities,
                        command = "haskell-language-server-wrapper",
                        settings = {
                            haskell = {
                                formattingProvider = "fourmolu",
                                hlintOn = true,
                                useSnippetsOnType = true,
                                useSimpleTypeCheck = true,
                            },
                        },
                    })
                end,

                ["lua_ls"] = function()
                    -- configure lua server (with special settings)
                    lspconfig["lua_ls"].setup({
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                -- make the language server recognize "vim" global
                                diagnostics = {
                                    globals = { "vim" },
                                },
                                completion = {
                                    callSnippet = "Replace",
                                },
                            },
                        },
                    })
                end,

                ["pest_ls"] = function()
                    require("pest-vim").setup({
                        capabilities = capabilities,
                    })
                end,

                ["rust_analyzer"] = function()
                    -- configure rust-analyzer server
                    lspconfig["rust_analyzer"].setup({
                        capabilities = capabilities,
                        settings = {
                            ["rust-analyzer"] = {
                                check = {
                                    command = "clippy",
                                },
                            },
                        },
                    })
                end,

                ["svelte"] = function()
                    -- configure svelte server
                    lspconfig["svelte"].setup({
                        capabilities = capabilities,
                        on_attach = function(client, bufnr)
                            vim.api.nvim_create_autocmd("BufWritePost", {
                                pattern = { "*.js", "*.ts" },
                                callback = function(ctx)
                                    -- Here use ctx.match instead of ctx.file
                                    client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
                                end,
                            })
                        end,
                    })
                end,

                ["taplo"] = function()
                    -- configure taplo server
                    lspconfig["taplo"].setup({
                        capabilities = capabilities,
                        filetypes = {
                            "toml",
                        },
                    })
                end,

                ["ts_ls"] = function()
                    lspconfig["ts_ls"].setup({
                        capabilities = capabilities,
                        settings = {
                            javascript = {
                                implicitProjectConfiguration = {
                                    checkJs = true,
                                },
                            },
                        },
                    })
                end,
            })
        end,
    },
}
