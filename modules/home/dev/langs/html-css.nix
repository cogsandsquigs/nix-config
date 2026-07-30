# Returns a list of specs: html and css/scss need different LSPs.
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
        extensions = {
            ".html" = "html";
            ".htm" = "html";
        };
        fmt = [
            "prettierd"
            "%{buffer_name}"
        ];
    }
    {
        lang = [
            "css"
            "scss"
        ];
        lsp = [
            {
                name = "vscode-css-language-server";
                cmd = [
                    "vscode-css-language-server"
                    "--stdio"
                ];
            }
        ];
        extensions = {
            ".css" = "css";
            ".scss" = "scss";
        };
        fmt = [
            "prettierd"
            "%{buffer_name}"
        ];
    }
]
