return {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
        "windwp/nvim-ts-autotag",
    },
    opts = { -- enable syntax highlighting
        highlight = {
            enable = true,
            disable = {
                "neotree", -- Disable so that treesitter doesn't try to parse file explorer.
            },
        },

        -- enable indentation
        indent = { enable = true },

        -- enable autotagging (w/ nvim-ts-autotag plugin)
        autotag = {
            enable = true,
        },

        -- ensure these language parsers are installed
        ensure_installed = {
            "asm",
            "astro",
            "bash",
            "bibtex",
            "c",
            "cpp",
            "css",
            "dockerfile",
            "gitignore",
            "glsl",
            "go",
            "gomod",
            "gosum",
            "gowork",
            "graphql",
            "haskell",
            "html",
            "ini",
            "javascript",
            "json",
            "kotlin",
            "latex",
            "lua",
            "markdown",
            "markdown_inline",
            "mermaid",
            "nix",
            "prisma",
            "query",
            "ron",
            "rust",
            "scss",
            "svelte",
            "tera",
            "tsx",
            "typescript",
            "vim",
            "vimdoc",
            "xml",
            "yaml",
        },

        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = "<C-space>",
                node_incremental = "<C-space>",
                scope_incremental = false,
                node_decremental = "<bs>",
            },
        },
    },
}
