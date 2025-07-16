return {
    "Saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
        text = {
            searching = "   Searching",
            loading = "   Loading",
            version = "   %s",
            prerelease = "   %s",
            yanked = "   %s",
            nomatch = "   No match",
            upgrade = "   %s",
            error = "   Error fetching crate",
        },
        completion = {
            cmp = { enabled = true },
        },
    },
}
