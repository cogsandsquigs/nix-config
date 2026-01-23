{ pkgs, ... }:
{

    home.packages = with pkgs; [
        alejandra # UN-official formatter (stable, opinionated!)
        nixfmt
        nil # Nix LSP
        # direnv # NOTE: Not needed! See: https://github.com/nix-community/nix-direnv
    ];
}
