{ pkgs, ... }: {
    pkgs = with pkgs; [ docker-compose-language-service ];

    # No `lsp`: compose files match by glob, which `extensions` cannot express, so an entry would
    # gain nothing and would drop helix's yaml-language-server fallback.

    fmt = [
        "prettierd"
        "%{buffer_name}"
    ];

    languages.docker-compose = { };
}
