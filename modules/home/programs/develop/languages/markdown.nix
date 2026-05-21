{ ... }:
{
    flake.modules.homeManager.develop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                marksman # Markdown LSP
                mdbook # Docs from markdown: https://rust-lang.github.io/mdBook/index.html
                dprint # formatter, only used here for now lol
            ];
        };
}
