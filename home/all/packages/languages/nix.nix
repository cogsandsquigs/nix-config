{pkgs, ...}: {
    home.packages = with pkgs; [
        alejandra # Formatter
        # direnv # NOTE: Not needed! See: https://github.com/nix-community/nix-direnv
    ];
}
