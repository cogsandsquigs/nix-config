{ lib, pkgs, ... }:
let
    markdownlintTool = [
        {
            lint-command = "markdownlint -s";
            lint-stdin = true;
            lint-formats = [
                "%f:%l %m"
                "%f:%l:%c %m"
                "%f: %l: %m"
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
            languages = lib.genAttrs [ "markdown" ] (_: markdownlintTool);
        }
    );

in
{
    pkgs = with pkgs; [
        marksman
        markdown-oxide
        markdownlint-cli
        efm-langserver
        mdbook
        prettierd
    ];

    # prettier, not dprint: the `fmt` gate has to run the same formatter the editor does, and dprint
    # fetches its markdown plugin from the network, which the Nix sandbox has no access to. Options come
    # from the repo's .prettierrc.json (printWidth 100, proseWrap "always") -- the same file treefmt
    # reads, so saving in the editor and running `nix fmt` cannot disagree.
    fmt = [
        "prettierd"
        "%{buffer_name}"
    ];

    lsp = [
        {
            name = "marksman";
            cmd = [
                "marksman"
                "server"
            ];
            except-features = [ "format" ];
        }
        {
            name = "markdown-oxide";
            cmd = [ "markdown-oxide" ];
            except-features = [ "format" ];
        }
        {
            name = "efm-langserver-md";
            cmd = [
                "efm-langserver"
                "-c"
                "${efmConfig}"
            ];
            only-features = [ "diagnostics" ];
        }
    ];

    # No extensions: nothing to bind without an `lsp`.
    languages.markdown = {
        extensions = [ ".md" ];

    };

    # editor-specific = {
    #     helix = {
    #         soft-wrap = {
    #             enable = true;
    #             wrap-at-text-width = true;
    #         };
    #     };
    # };
}
