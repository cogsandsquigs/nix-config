{ pkgs, ... }: {
    home.packages = with pkgs; [
        rustup # Rust tooling installer
        #cargo-afl # Fuzzing
        cargo-watch # Rebuild on change for Rust projects
        cargo-workspaces # Workspace management
        cargo-license # License checking
        trunk # Wasm packaging for Rust
    ];
}
