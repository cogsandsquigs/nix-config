{ pkgs, ... }:
let
    # See: https://dprint.dev/config/
    dprint-config = builtins.toFile "dprint.json" (
        builtins.toJSON {
            lineWidth = 100;
            markdown = {
                lineWidth = 100;
                textWrap = "always";
            };
            plugins = [ "https://plugins.dprint.dev/markdown-0.22.0.wasm" ];
        }
    );
in
{
    pkgs = with pkgs; [
        # marksman # Markdown LSP -- heavy package, excluded for now
        mdbook
        dprint
    ];

    fmt = [
        "dprint"
        "fmt"
        "--config=${dprint-config}"
        "--stdin"
        "%{buffer_name}"
    ];

    # No extensions: nothing to bind without an `lsp`.
    languages.markdown = { };
}
