vim.cmd("let g:netrw_liststyle = 3") -- Make file explorer match output of `tree`

local opt = vim.opt

-- Line numbers
-- opt.relativenumber = true
opt.number = true

opt.textwidth = 80 -- Wrap text at 80 characters

-- Tabs, Indentation, and Whitespace
opt.tabstop = 4 -- 4 spaces for tabs
opt.shiftwidth = 4 -- indentation is 4 spaces wide
opt.softtabstop = 4 -- 4 spaces for tabs
opt.expandtab = true -- DON'T expand tabs to spaces
opt.autoindent = true -- Auto-indent on new line
opt.listchars = {
    tab = "→ ", -- Tabs are always "→   " (2nd char used as much as possible in width of tab)
    multispace = "·", -- 2 or more spaces are always "·" repeated, while single spaces are blank
}

opt.wrap = false -- DON'T wrap lines if they expand outside of window borders

-- Search
opt.ignorecase = true -- Ignore letter case in searches
opt.smartcase = true -- If you include mix-case in search, assumes case-sensitive search is desired REGARDLESS of `opt.ignorecase`

opt.cursorline = true -- Highlights the line the cursor is currently on, INCLUDING line number (but not other/relative line numbers)

-- Turn on termguicolors for theme to work
-- (Have to use iTerm2 or any other true color terminal)
opt.termguicolors = true -- Turn on termguicolors for themes to work
opt.background = "dark" -- Want dark theme
opt.signcolumn = "yes" -- Show sign column so text doesn't shift

-- Backspace
opt.backspace = "indent,eol,start" -- Allow backspace on indent, end-of-line, or insert mode start position

-- Clipboard
opt.clipboard:append("unnamedplus") -- Use system clipboard as default register

-- Completions
-- vim.g.lazyvim_blink_main = true -- force use the main branch to fix bugs!

-- Highlights for indents
vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#f38ba8" })
vim.api.nvim_set_hl(0, "RainbowMaroon", { fg = "#eba0ac" })
vim.api.nvim_set_hl(0, "RainbowPeach", { fg = "#fab387" })
vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#f9e2af" })
vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#a6e3a1" })
vim.api.nvim_set_hl(0, "RainbowTeal", { fg = "#94e2d5" })
vim.api.nvim_set_hl(0, "RainbowSky", { fg = "#89dceb" })
vim.api.nvim_set_hl(0, "RainbowSapphire", { fg = "#74c7ec" })
vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#89b4fa" })
vim.api.nvim_set_hl(0, "RainbowLavender", { fg = "#b4befe" })
vim.api.nvim_set_hl(0, "RainbowPink", { fg = "#f5c2e7" })
vim.api.nvim_set_hl(0, "RainbowMauve", { fg = "#f38ba8" })
