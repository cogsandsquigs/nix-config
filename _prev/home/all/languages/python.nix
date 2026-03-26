{ pkgs, ... }:
{
    home.packages = with pkgs; [
        python3

        # Python tooling, courtesy of Astral.sh
        uv # Project manager
        ty # LSP, typechecker
        ruff # Formatter, linter
    ];
}
