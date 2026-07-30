{ pkgs, ... }: {
    lang = [
        "json"
        "jsonc"
    ];

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

    file-types.json = [
        "json"
        "prettierrc"
    ];

    # `prettierrc` has no counterpart below: .prettierrc is a whole filename, not an extension.
    extensions = {
        ".json" = "json";
        ".jsonc" = "jsonc";
    };
}
