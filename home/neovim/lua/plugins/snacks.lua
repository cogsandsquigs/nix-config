return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
        lazygit = { enabled = true },
        toggleterm = { enabled = true },
        explorer = { enabled = false },

        dashboard = {
            enabled = true,
            preset = {
                keys = {
                    { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
                    { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                    {
                        icon = " ",
                        key = "g",
                        desc = "Find Text",
                        action = ":lua Snacks.dashboard.pick('live_grep')",
                    },
                    {
                        icon = " ",
                        key = "r",
                        desc = "Recent Files",
                        action = ":lua Snacks.dashboard.pick('oldfiles')",
                    },
                    {
                        icon = " ",
                        key = "c",
                        desc = "Config",
                        action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
                    },
                    { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                    {
                        action = ":Mason",
                        desc = "Mason",
                        icon = " ",
                        key = "m",
                    },
                    {
                        icon = "󰒲 ",
                        key = "l",
                        desc = "Lazy",
                        action = ":Lazy",
                        enabled = package.loaded.lazy ~= nil,
                    },

                    { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                },
            },
        },

        indent = {
            indent = {
                enabled = true, -- enable highlighting the current scope
                priority = 1,
                char = "│",
                -- NOTE: No highlight option here to gray out "normal" tabs.
            },
            scope = {
                enabled = true, -- enable highlighting the current scope
                priority = 200,
                char = "│",
                underline = false, -- underline the start of the scope
                only_current = false, -- only show scope in the current window
                hl = {
                    -- WARN: Gotta put "spacers" in between the colors because otherwise it doesn't cycle thru all the
                    -- highlight groups.
                    "RainbowRed",
                    "",
                    "",
                    "",
                    "RainbowMaroon",
                    "",
                    "",
                    "",
                    "RainbowPeach",
                    "",
                    "",
                    "",
                    "RainbowYellow",
                    "",
                    "",
                    "",
                    "RainbowGreen",
                    "",
                    "",
                    "",
                    "RainbowTeal",
                    "",
                    "",
                    "",
                    "RainbowSky",
                    "",
                    "",
                    "",
                    "RainbowSapphire",
                    "",
                    "",
                    "",
                    "RainbowBlue",
                    "",
                    "",
                    "",
                    "RainbowLavender",
                    "",
                    "",
                    "",
                    "RainbowPink",
                    "",
                    "",
                    "",
                    "RainbowMauve",
                },
            },
        },
    },

    keys = {
        {
            "<leader>lg",
            function()
                Snacks.lazygit.open()
            end,
            desc = "Open lazy git",
        },
        {
            "<c-`>",
            function()
                Snacks.terminal.toggle()
            end,
            desc = "Toggle Terminal",
        },
    },
}
