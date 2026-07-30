{ pkgs, ... }: {
    pkgs = with pkgs; [
        vscode-langservers-extracted
        jsonnet-language-server
    ];

    lsp = [
        {
            name = "vscode-json-language-server";
            cmd = [
                "vscode-json-language-server"
                "--stdio"
            ];
        }
    ];

    fmt = [
        "prettierd"
        "%{buffer_name}"
    ];

    languages = {
        # `.js.map` and friends are helix's own entries; a client matching on the last dot will
        # see them as `.map`.
        json.extensions = [
            ".json"
            ".arb"
            ".ipynb"
            ".geojson"
            ".gltf"
            ".webmanifest"
            ".js.map"
            ".ts.map"
            ".css.map"
            ".jsonl"
            ".avsc"
            ".ldtk"
            ".ldtkl"
            ".sublime-build"
            ".sublime-color-scheme"
            ".sublime-commands"
            ".sublime-completions"
            ".sublime-keymap"
            ".sublime-macro"
            ".sublime-menu"
            ".sublime-mousemap"
            ".sublime-project"
            ".sublime-settings"
            ".sublime-theme"
            ".sublime-workspace"
        ];
        jsonc.extensions = [ ".jsonc" ];
    };
}
