{ pkgs, ... }: {
    home.packages = with pkgs; [

        # LSPs and such
        texlab # LSP
        texpresso # Live rendering of .tex -> .pdf

        (texlive.withPackages (
            ps: with ps; [
                latexindent

                latex
                latexmk
                pdftex

                # Diagramming
                tikz-cd
                tikz-ext
            ]
        ))
    ];
}
