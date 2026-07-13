{ pkgs, ... }: {
    lang = [ "rust" ];

    pkgs = with pkgs; [
        rustup
        cargo-watch # Project watching
        cargo-workspaces # Workspace management
        cargo-license # License checking
        trunk # Rust WASM compiler / bundler
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
