{pkgs, ...}: {
    home.packages = with pkgs; [
        jetbrains.idea-ultimate
        neovim
        helix
        tree-sitter # For language support
    ];
}
