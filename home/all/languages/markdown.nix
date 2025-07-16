{ pkgs, ... }:
{
    home.packages = with pkgs; [
        marksman # Markdown LSP
        mdbook # Docs from markdown: https://rust-lang.github.io/mdBook/index.html
        dprint # General formatter, only using it for markdown right now
    ];
}
