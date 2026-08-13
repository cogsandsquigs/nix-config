{ pkgs, lib, ... }:
let
    eslintTool = [
        {
            # `npx --no-install`, never `-y`: eslint is a PROJECT dependency, so it lives in
            # ./node_modules/.bin and is not on PATH. `-y` would fetch it from the network mid-lint
            # instead of failing, and `lint-ignore-exit-code` below would swallow the difference,
            # leaving diagnostics silently empty. `--no-install` fails fast when the project has no
            # eslint, which is the honest answer.
            lint-command = "npx --no-install eslint --stdin --stdin-filename \${INPUT}";
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
            name = "efm-langserver-js-ts";
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
