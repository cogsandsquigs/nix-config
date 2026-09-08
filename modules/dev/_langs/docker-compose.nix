{ pkgs, ... }: {
    pkgs = with pkgs; [ docker-compose-language-service ];

    # No `lsp`: compose files match by glob, and there is no server to bind -- a `filenames`
    # list (`docker-compose.yml`, `compose.yaml`, ...) would gain nothing and drop helix's
    # yaml-language-server fallback.

    fmt = [
        "prettierd"
        "%{buffer_name}"
    ];

    languages.docker-compose = { };
}
