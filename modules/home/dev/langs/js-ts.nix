{ pkgs, lib, ... }:
let
    eslintTool = [
        {
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
            root-markers = [ ".git/" ];
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
        bun
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
}
