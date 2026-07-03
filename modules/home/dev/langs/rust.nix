{ pkgs, ... }:
{
    home.packages = with pkgs; [
        rustup
        #cargo-afl # Fuzzing
        cargo-watch
        cargo-workspaces
        trunk # Wasm packaging for Rust
    ];
}
