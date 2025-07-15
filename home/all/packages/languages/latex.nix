{ pkgs, ... }:
{
    home.packages = with pkgs; [
        # texliveFull # Install `latexmk` + co (unneeded) for vimtex (see neovim config)
        texliveSmall
        texlab
        python313Packages.pylatexenc # Needed for converting inline LaTeX in MD to unicode
    ];
}
