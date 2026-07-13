# Returns a list of specs: html, css, and scss each need different (or no) LSPs.
{ pkgs, ... }: [
    {
        lang = [ "html" ];
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
    }
    {
        lang = [ "css" ];
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
    }
    {
        lang = [ "scss" ];
        fmt = [
            "prettierd"
            "%{buffer_name}"
        ];
    }
]
