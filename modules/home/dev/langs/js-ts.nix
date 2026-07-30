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
            languages = lib.genAttrs [ "javascript" "typescript" "svelte" ] (_: eslintTool);
        }
    );
in
{
    lang = [
        "javascript"
        "typescript"
        "svelte"
    ];

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

    # The *react ids are not cosmetic -- tsserver picks the JSX-aware parser off them.
    extensions = {
        ".ts" = "typescript";
        ".mts" = "typescript";
        ".cts" = "typescript";
        ".tsx" = "typescriptreact";
        ".js" = "javascript";
        ".mjs" = "javascript";
        ".cjs" = "javascript";
        ".jsx" = "javascriptreact";
        ".svelte" = "svelte";
    };

    fmt = [
        "prettierd"
        "%{buffer_name}"
    ];
}
