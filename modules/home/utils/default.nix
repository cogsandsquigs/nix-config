# General CLI utilities.
{ pkgs, ... }:
{
    imports = [
        ./gpg.nix
        ./yazi.nix
        ./zellij.nix
    ];

    home.packages = with pkgs; [
        fzf
        ripgrep
        jq
        just
        tree
        magic-wormhole
        fontconfig
        inetutils
        eza
        dust
        bat
        zoxide
        lazygit
        fastfetch
    ];

    programs.eza = {
        colors = "auto";
        git = true;
        icons = true;
    };

    programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
    };
}
