return {
    "nvim-lualine/lualine.nvim",

    event = "VeryLazy",

    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },

    after = "catppuccin",

    opts = function()
        local lazy_status = require("lazy.status")

        return {

            -- options = {
            -- 	theme = "catppuccin",
            -- },

            -- sections = {
            -- 	lualine_x = {
            -- 		{
            -- 			lazy_status.updates,
            -- 			cond = lazy_status.has_updates,
            -- 		},
            -- 		{ "encoding" },
            -- 		{
            -- 			"fileformat", -- Has to do with line endings, NOT OS type
            -- 			symbols = {
            -- 				unix = "", -- e712
            -- 				dos = "", -- e70f
            -- 				mac = "", -- e711
            -- 			},
            -- 		},
            -- 		{ "filetype" },
            -- 	},
            -- },

            options = {
                theme = "catppuccin",
                component_separators = "|",
                section_separators = { left = "", right = "" },
            },
            sections = {
                lualine_a = {
                    {
                        "mode",
                        separator = { left = "" },
                        left_padding = 2,
                        right_padding = 2,
                    },
                },
                lualine_b = {
                    "branch",
                    "diff",
                    "diagnostics",
                },
                lualine_c = {
                    -- add your center compoentnts here in place of this comment
                    { "%=", separator = "" }, -- NOTE: The `separator = ""` is because when not included, there appears a *very* ugly separator to the left of the component
                    { "filename" },
                },
                lualine_x = {},
                lualine_y = {

                    {
                        lazy_status.updates,
                        cond = lazy_status.has_updates,
                    },
                    { "filetype" },
                    { "encoding" },
                    {
                        "fileformat", -- Has to do with line endings, NOT OS type
                        symbols = {
                            unix = "", -- e712
                            dos = "", -- e70f
                            mac = "", -- e711
                        },
                    },
                },
                lualine_z = {
                    {
                        "location",
                        separator = { right = "" },
                        left_padding = 2,
                        right_padding = 2,
                    },
                },
            },
            inactive_sections = {
                lualine_a = { "filename" },
                lualine_b = {},
                lualine_c = {},
                lualine_x = {},
                lualine_y = {},
                lualine_z = { "location" },
            },
            tabline = {},
            extensions = {},
        }
    end,
}
