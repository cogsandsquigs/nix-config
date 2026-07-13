{ pkgs, ... }: {
    lang = [ "rust" ];

    pkgs = with pkgs; [
        rustup
        cargo-watch
        cargo-workspaces
        cargo-license
        trunk
    ];

    lsp = [
        {
            name = "rust-analyzer";
            cmd = [ "rust-analyzer" ];
            config.rust-analyzer = {
                check.command = "clippy";
                procMacro.enable = true;
                cargo.buildScripts.enable = true;
            };
        }
    ];

    fmt = [ "rustfmt" ];
}
