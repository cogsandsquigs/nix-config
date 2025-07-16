{ pkgs, ... }:
{
    home.packages = with pkgs; [
        jetbrains.idea-ultimate
        tree-sitter # For language support
    ];
}
