{ pkgs, lib, ... }:
let
    eslintTool = [
        {
            lint-command = "npx -y eslint --stdin --stdin-filename \${INPUT}";
            lint-ignore-exit-code = true;
            lint-stdin = true;
            lint-after-open = true;
            lint-formats = [
                "%+P%f"
                "%*[ ]%l:%c%*[ ]%t%*[^ ]%*[ ]%m"
                "%-O"
            ];
        }
    ];

    efmConfig = builtins.toFile "efm-config.yaml" (
        lib.generators.toYAML { } {
            version = 2;
            root-markers = [
                ".git/"
                "package.json"
            ];
            lint-debounce = "1s";
            # Keys are the ids helix sends: javascriptreact/typescriptreact, not jsx/tsx.
            languages = lib.genAttrs [ "javascript" "javascriptreact" "typescript" "typescriptreact" ] (
                _: eslintTool
            );
        }
    );
in
{
    pkgs = with pkgs; [
        nodejs
        aube
        deno

        typescript-language-server
        efm-langserver
        prettierd
    ];

    lsp = [
        {
            name = "typescript-language-server";
            cmd = [
                "typescript-language-server"
                "--stdio"
            ];
        }
        {
            name = "efm-langserver";
            cmd = [
                "efm-langserver"
                "-c"
                "${efmConfig}"
            ];
            only-features = [ "diagnostics" ];
        }
    ];

    fmt = [
        "prettierd"
        "%{buffer_name}"
    ];

    languages = {
        javascript.extensions = [
            ".js"
            ".mjs"
            ".cjs"
            ".rules"
            ".es6"
            ".pac"
        ];
        javascript.filenames = [
            "jakefile"
            ".node_repl_history"
        ];
        jsx = {
            extensions = [ ".jsx" ];
            language-id = "javascriptreact";
        };
        typescript.extensions = [
            ".ts"
            ".mts"
            ".cts"
        ];
        tsx = {
            extensions = [ ".tsx" ];
            language-id = "typescriptreact";
        };
    };
}
