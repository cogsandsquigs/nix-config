{ pkgs, ... }: {
    home.packages = with pkgs; [
        nixfmt # Official/default formatter (per-file, used by the editor)
        treefmt # Whole-tree formatter (alt) — driven by ./treefmt.toml; also what `nix fmt` runs
        nixd # Official community Nix LSP
        #nil # Nix LSP, backup (essentially) as it's kinda worse
    ];
}
