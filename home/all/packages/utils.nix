{ pkgs, ... }:
{
    home.packages = with pkgs; [
        zoxide # Better CD
        fzf # Fuzzy finder
        eza # Better ls
        dust # Better du
        bat # Better cat
        ripgrep
        jq
        just
        tree
        gnupg # Signatures
        fastfetch # System info
        magic-wormhole
        fontconfig
        yazi # Terminal file manager
    ];
}
