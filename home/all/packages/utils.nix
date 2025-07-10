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
    mdbook # Docs from MD: https://rust-lang.github.io/mdBook/index.html
    magic-wormhole
    fontconfig
    nnn # Nice terminal file manager
  ];
}
