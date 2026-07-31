{ pkgs, lib, ... }: {
    pkgs = with pkgs; [
        rustup
        # rustup ships a `rust-analyzer` shim that dispatches to a component it does not install, so
        # the bare name resolves to something that exits without answering LSP initialize -- the
        # client then waits forever. Higher priority than the shim to win the name collision.
        (lib.hiPrio rust-analyzer)
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

    languages.rust.extensions = [ ".rs" ];
}
