{ pkgs, ... }:
{

    home.packages = with pkgs; [
        nixfmt # Official/default formatter
        nil # Nix LSP
        # direnv # NOTE: Not needed! See: https://github.com/nix-community/nix-direnv
    ];
}
