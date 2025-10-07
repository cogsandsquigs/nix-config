{ pkgs, ... }:
{
    home.packages = with pkgs; [
        # marksman # Markdown LSP # NOTE: Don't use, req. DotNET (Long compile!/errors!)
        mdbook # Docs from markdown: https://rust-lang.github.io/mdBook/index.html
        dprint # General formatter, only using it for markdown right now
    ];
}
