{ pkgs, ... }: {
    pkgs = with pkgs; [
        # marksman # Markdown LSP -- heavy package, excluded for now
        mdbook
        prettierd
    ];

    # prettier, not dprint: the `fmt` gate has to run the same formatter the editor does, and dprint
    # fetches its markdown plugin from the network, which the Nix sandbox has no access to. Options come
    # from the repo's .prettierrc.json (printWidth 100, proseWrap "always") -- the same file treefmt
    # reads, so saving in the editor and running `nix fmt` cannot disagree.
    fmt = [
        "prettierd"
        "%{buffer_name}"
    ];

    # No extensions: nothing to bind without an `lsp`.
    languages.markdown = { };
}
