{ pkgs, ... }: {
    pkgs = with pkgs; [
        yaml-language-server
        prettierd
    ];

    lsp = [
        {
            name = "yaml-language-server";
            cmd = [
                "yaml-language-server"
                "--stdio"
            ];
        }
    ];

    fmt = [
        "prettierd"
        "%{buffer_name}"
    ];

    languages.yaml = {
        extensions = [
            ".yml"
            ".yaml"
            ".sublime-syntax"
        ];
        # Dotfiles whose whole name identifies them; prettier's rc is YAML, not JSON.
        filenames = [
            ".prettierrc"
            ".clangd"
            ".clang-format"
            ".clang-tidy"
        ];
    };
}
