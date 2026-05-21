{ ... }:
{
    flake.modules.homeManager.develop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                marksman # Markdown LSP # NOTE: Don't use, req. DotNET (Long compile!/errors!)
                mdbook # Docs from markdown: https://rust-lang.github.io/mdBook/index.html
                dprint # formatter, only used here for now lol
            ];
        };
}
