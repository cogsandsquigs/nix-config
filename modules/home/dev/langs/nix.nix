{ pkgs, ... }: {
    lang = [ "nix" ];

    pkgs = with pkgs; [
        nixfmt # Official/default formatter (per-file, used by the editor)
        treefmt # Whole-tree formatter (alt) — driven by ./treefmt.toml; also what `nix fmt` runs
        nixd # Official community Nix LSP
        nil # Nix LSP, backup — kinda worse, kept for reference
    ];

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
}
