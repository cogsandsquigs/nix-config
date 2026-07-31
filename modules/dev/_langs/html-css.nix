# Returns a list of toolchains: html and css/scss need different LSPs.
{ pkgs, ... }: [
    {
        pkgs = with pkgs; [
            zola
            vscode-langservers-extracted
            prettierd
        ];
        lsp = [
            {
                name = "vscode-html-language-server";
                cmd = [
                    "vscode-html-language-server"
                    "--stdio"
                ];
            }
        ];
        fmt = [
            "prettierd"
            "%{buffer_name}"
        ];
        languages.html.extensions = [
            ".html"
            ".htm"
            ".shtml"
            ".xhtml"
            ".xht"
            ".jsp"
            ".asp"
            ".aspx"
            ".jshtm"
            ".volt"
            ".rhtml"
            ".cshtml"
        ];
    }
    {
        lsp = [
            {
                name = "vscode-css-language-server";
                cmd = [
                    "vscode-css-language-server"
                    "--stdio"
                ];
            }
        ];
        fmt = [
            "prettierd"
            "%{buffer_name}"
        ];
        languages = {
            css.extensions = [ ".css" ];
            scss.extensions = [ ".scss" ];
        };
    }
]
