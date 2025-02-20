return {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    version = "*",
    after = "catppuccin", -- So that the highlights work w/ the theme properly

    opts = {
        -- Set the highlights to use our theme
        highlights = require("catppuccin.groups.integrations.bufferline").get(),

        options = {
            mode = "tabs",
            separator_style = "thin",
            themeable = true,

            indicator = {
                style = "underline",
            },

            always_show_bufferline = true,
        },
    },
}
