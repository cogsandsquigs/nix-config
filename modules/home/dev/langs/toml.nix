{ pkgs, ... }: {
    pkgs = with pkgs; [ taplo ];

    # Drops helix's `tombi` fallback, which is not installed anyway.
    lsp = [
        {
            name = "taplo";
            cmd = [
                "taplo"
                "lsp"
                "stdio"
            ];
        }
    ];

    fmt = [
        "taplo"
        "fmt"
        "-o=align_entries=true"
        "-o=align-comments"
        "-o=allowed_blank_lines=1"
        "-o=indent_entries=true"
        "-o=indent_tables=true"
        "-o=indent_string=    "
        "-o=reorder_arrays=false"
        "-o=reorder_keys=true"
        "-"
    ];

    languages.toml = {
        extensions = [ ".toml" ];
        filenames = [
            "Cargo.lock"
            "uv.lock"
            "pdm.lock"
            "poetry.lock"
        ];
    };
}
