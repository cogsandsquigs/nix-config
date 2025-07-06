-- Add additional filetypes for Neovim to recognize

vim.filetype.add({
    -- Filetype detection based on file extension
    extension = {
        mdx = "mdx",
        tf = "terraform",
        tera = "tera",
    },

    -- Filetype detection based on file name
    filename = {
        Caddyfile = "caddy",
    },
})
