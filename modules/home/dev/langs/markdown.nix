{ pkgs, ... }:
{
    home.packages = with pkgs; [
        # marksman # Markdown LSP # WARN: Heavy package, not included rn b/c of that...
        mdbook # Docs from markdown: https://rust-lang.github.io/mdBook/index.html
        dprint # formatter, only used here for now lol
    ];
}
