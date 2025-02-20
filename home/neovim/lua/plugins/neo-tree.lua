return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
        "MunifTanjim/nui.nvim",
        -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    opts = {
        close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
        default_component_configs = {
            indent = {
                expander_collapsed = "", -- arrow when folder is closed
                expander_expanded = "", -- arrow when folder is open
            },

            name = {
                trailing_slash = false,
                use_git_status_colors = true,
                highlight = "NeoTreeFileName",
            },

            git_status = {
                symbols = {
                    -- Change type
                    added = "󱇬",
                    modified = "",
                    deleted = "✖", -- this can only be used in the git_status source
                    renamed = "󰁕", -- this can only be used in the git_status source
                    -- Status type
                    untracked = "★",
                    ignored = "◌",
                    unstaged = "󰍴",
                    staged = "󰸞",
                    conflict = "",
                },
            },
        },

        window = {
            position = "left",
            width = 30,
            mappings = {
                ["e"] = {
                    "toggle_node",
                    nowait = false, -- disable `nowait` if you have existing combos starting with this char that you want to use
                },
            },
        },

        filesystem = {
            filtered_items = {
                visible = false,
                hide_dotfiles = false,
                hide_gitignored = false,
                hide_by_name = {
                    "node_modules",
                    "target",
                    "lazy-lock.json",
                    "package-lock.json",
                    "bun.lockb",
                    ".astro",
                    ".svelte",
                    "dist-newstyle", -- Haskell
                },
                hide_by_pattern = {
                    "*/.git",
                },
                never_show = {
                    ".git", -- Because git directories should never be directly interfaced with - only through git CLI.
                    ".DS_Store",
                    "thumbs.db",
                },
            },
        },
    },
}
