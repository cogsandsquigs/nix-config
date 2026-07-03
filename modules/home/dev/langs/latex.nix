{ pkgs, ... }: {
    home.packages = with pkgs; [
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
