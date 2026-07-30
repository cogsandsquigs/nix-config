{ pkgs, ... }: {
    pkgs = with pkgs; [
        go # Bundles `gofmt`
        gopls # Primary LSP
        golangci-lint-langserver # Secondary LSP
        golangci-lint # Linter, used by above
        delve # Debugger
    ];

    lsp = [
        {
            name = "gopls";
            cmd = [
                "gopls"
                "-logfile=/tmp/gopls.log"
                "serve"
            ];
            config = {
                "ui.diagnostic.staticcheck" = true;
                hints = {
                    assignVariableTypes = true;
                    compositeLiteralFields = true;
                    constantValues = true;
                    functionTypeParameters = true;
                    parameterNames = true;
                    rangeVariableTypes = true;
                };
            };
        }
        {
            name = "golangci-lint-lsp";
            cmd = [ "golangci-lint-langserver" ];
            config = {
                command = [
                    "golangci-lint"
                    "run"
                    "--output.json.path"
                    "stdout"
                    "--show-stats=false"
                    "--issues-exit-code=1"
                ];
            };
        }
    ];

    fmt = [ "gofmt" ];

    editor-specific = {
        helix = {
            indent = {
                tab-width = 4;
                unit = "\t";
            };
        };
    };

    languages = {
        go.extensions = [ ".go" ];
        # No extensions: go.mod is a bare filename, which `extensions` cannot express.
        gomod = { };
    };
}
