-- NOTE: This is mainly for programming languages that don't have linters built into their LSP servers, OR that have separate linters that are more powerful than the built-in ones.
return {
    "mfussenegger/nvim-lint",
    event = { "LazyFile" },
    opts = {
        linters_by_ft = {
            cmake = { "cmakelint" },
            --[[
            javascript = { "eslint_d" },
            typescript = { "eslint_d" },
            javascriptreact = { "eslint_d" },
            typescriptreact = { "eslint_d" },
            svelte = { "eslint_d" },
            astro = { "eslint_d" }, 
            ]]
            c = { "clang" },
            cpp = { "clang" },
            python = { "pylint" },
            haskell = { "hlint" },

            -- NOTE: Rust linting via clippy (currently configured in `lspconfig.lua` via rust-analyzer)
        },

        -- Custom linters
        linters = {
            clang = {
                cmd = "clang",
            },
        },
    },
}
