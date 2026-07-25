{ pkgs, ... }: {
    lang = [ "go" ];

    pkgs = with pkgs; [
        go
        gopls
    ];

    lsp = [
        {
            name = "gopls";
            cmd = [
                "gopls"
                "-logfile=/tmp/gopls.log"
                "serve"
            ];
            config = {
                "ui.diagnostic.staticcheck" = true;
            };
        }
    ];

    fmt = [ ];
}
