return {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "TodoTrouble", "TodoTelescope" },
    event = "LazyFile",
    opts = {},
}

-- This is how the comments look:

-- TODO:
-- FIX:
-- HACK:
-- WARN:
-- PERF:
-- OPTIM:
-- BUG:
-- NOTE:
-- TEST:
