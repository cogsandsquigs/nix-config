-- Add additional filetypes for Neovim to recognize

vim.filetype.add({
    extension = {
        mdx = "mdx",
        tf = "terraform",
        tera = "tera",
        Caddyfile = "Caddyfile",
    },
})
