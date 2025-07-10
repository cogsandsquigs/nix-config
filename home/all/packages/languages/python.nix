{ pkgs, ... }:
{
    home.packages = with pkgs; [
        python3
        black # Formatter
        pyright # Typechecker
        pylint # Linter
    ];
}
