{ pkgs, ... }: {
    pkgs = with pkgs; [
        nixfmt # Official/default formatter (per-file, used by the editor)
        treefmt # Whole-tree formatter (alt) -- driven by ./treefmt.toml; also what `nix fmt` runs
        nixd # Official community Nix LSP
        nil # Nix LSP, live fallback -- see the note on `lsp` below
    ];

    # BOTH servers run on every .nix file, deliberately. `languages.nix` declares no `lsp` of its own,
    # so it inherits this whole list, and `nixd` comes first because it is the better of the two. The
    # redundancy IS the feature: when `nixd` dies mid-session, `nil` is already attached and keeps
    # answering, instead of leaving the file with no server at all. Do not narrow this to one server.
    lsp = [
        {
            name = "nixd";
            cmd = [ "nixd" ];
        }
        {
            name = "nil";
            cmd = [
                "nil"
                "--stdio"
            ];
            config.nil.flake.autoArchive = true;
        }
    ];

    fmt = [
        "nixfmt"
        "--width=100"
        "--indent=4"
        "--quiet"
        "--strict"
        "-"
    ];

    languages.nix.extensions = [ ".nix" ];
}
