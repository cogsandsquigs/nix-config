{ pkgs, ... }:
{
    home.packages = with pkgs; [
        fzf # Fuzzy finder
        dust # Better du
        bat # Better cat
        ripgrep
        jq
        just
        tree
        fastfetch # System info
        magic-wormhole
        fontconfig
    ];
}
