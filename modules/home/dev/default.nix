# Development environments and languages tools (formatters, LSPs, etc.)
{ pkgs, ... }: {
    imports = [
        ./ide.nix
        ./direnv.nix
        ./containers.nix

        ./editor
        ./langs
    ];

    home.packages = with pkgs; [
        # Benchmarking
        hyperfine

        # API querying/development
        postman

        # AI stuffs (work *blech*)
        claude-code
        claude-monitor
    ];
}
