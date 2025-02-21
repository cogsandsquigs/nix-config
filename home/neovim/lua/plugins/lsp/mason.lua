return {
    {
        "williamboman/mason.nvim",
        dependencies = {
            -- NOTE: For some reason this plugin needs to be a dependency of `mason.nvim`, so that's why it's loaded
            -- here.
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            -- import mason
            local mason = require("mason")

            -- import mason-lspconfig
            local mason_lspconfig = require("mason-lspconfig")

            -- enable mason and configure icons
            mason.setup({
                ui = {
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗",
                    },
                },
            })

            mason_lspconfig.setup({ -- list of servers for mason to install
                ensure_installed = {
                    "astro",
                    "clangd",
                    "cmake",
                    "cssls",
                    "emmet_ls",
                    "glsl_analyzer",
                    "graphql",
                    "hls",
                    "html",
                    "lua_ls",
                    "marksman",
                    "nil_ls",
                    "pest_ls",
                    "prismals",
                    -- "pyright", -- NOTE: Using local install
                    "rust_analyzer",
                    "svelte",
                    "tailwindcss",
                    "taplo",
                    "texlab",
                    "ts_ls",
                },
            })
        end,
    },
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        -- NOTE: This plugin needs to be a NON-DEPENDENCY and CANNOT BE LAZY-LOADED. Otherwise it won't be able to run
        -- the install command for the formatters/tools/etc.
        lazy = false,
        opts = {
            ensure_installed = {
                -- "black", -- python formatter -- NOTE: Using local install
                "clang-format", -- C/C++/etc. formatter
                "cmakelint", -- CMake linter
                "eslint_d", -- js linter
                "fourmolu", -- Haskell formatter
                "hlint", -- Haskell linter
                "isort", -- python formatter
                "ktfmt", -- Kotlin formatter
                "ktlint", -- Kotlin linter + formatter (not used)
                "latexindent",
                -- "nixpkgs-fmt", -- Nix formatter NOTE: Using local install of alejandra instead
                "prettierd", -- prettier formatter
                -- "pylint", -- python linter NOTE: Using local install
                "shellcheck", -- Shell script linter,
                "sqlfluff", -- SQL formatter
                "stylua", -- lua formatter
                "taplo", -- TOML formatter
                -- NOTE: Not installing this with tool-installer as it is recommended to use the system-installed
                -- version.
                -- "rustfmt", -- rust formatter
            },

            auto_update = true,
            run_on_start = true,
        },
    },
}
