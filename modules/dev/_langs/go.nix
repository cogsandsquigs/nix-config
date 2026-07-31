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

        # gofmt would mangle a go.mod (that needs `go mod edit -fmt`), and golangci-lint has nothing
        # to say about it, so drop both and let gopls format it over LSP. No extensions: helix
        # matches go.mod by glob, and nothing else here can express a bare filename.
        gomod = {
            lsp = [ "gopls" ];
            fmt = [ ];
        };
    };
}
