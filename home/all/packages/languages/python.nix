{ pkgs, ... }:
{
    home.packages = with pkgs; [
        python3
        ruff # Formatter, linter, typechecker, etc...
        # black # Formatter
        # pyright # Typechecker
        # pylint # Linter
    ];
}
