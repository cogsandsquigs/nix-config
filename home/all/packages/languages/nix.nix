{pkgs, ...}: {
    home.packages = with pkgs; [
        alejandra # Formatter
        nil # Nix LSP
        # direnv # NOTE: Not needed! See: https://github.com/nix-community/nix-direnv
    ];
}
