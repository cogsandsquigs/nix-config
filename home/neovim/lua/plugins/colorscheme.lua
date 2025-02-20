return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,

    -- NOTE: The configuration for this plugin is required to be wrapped in a `config` function for some reason,
    -- at least as of catppuccin/nvim@7946d1a
    config = function()
        return {
            flavour = "mocha",

            background = {
                light = "latte",
                dark = "mocha",
            },

            integrations = {
                blink_cmp = true,
                gitsigns = true,
                treesitter = true,
                bufferline = true,
                telescope = {
                    enabled = true,
                },
                notify = true,
                dashboard = true,
            },
        }
    end,
}
