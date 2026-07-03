{ pkgs, ... }: {
    home.packages = with pkgs; [

        # LSPs and such
        texlab # LSP
        texpresso # Live rendering of .tex -> .pdf
        texlivePackages.latexindent # Formatting

        (texlive.withPackages (
            ps: with ps; [
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
