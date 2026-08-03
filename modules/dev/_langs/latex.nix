{ pkgs, ... }: {
    pkgs = with pkgs; [
        texlab
        texpresso
        (texlive.withPackages (
            ps: with ps; [
                latexindent
                latex
                latexmk
                pdftex
                tikz-cd
                tikz-ext
            ]
        ))
    ];

    lsp = [
        {
            name = "texlab";
            cmd = [ "texlab" ];
            # No `forwardSearch`: it names a PDF viewer to jump to the cursor's page, and no viewer here
            # is set up for it. `build.forwardSearchAfter` is therefore off too -- the two are only
            # meaningful as a pair, and asking texlab to run a viewer it has no path for did nothing.
            config.texlab = {
                build.onSave = true;
                chktex.onEdit = true;
            };
        }
    ];

    fmt = [
        "latexindent"
        "-"
    ];

    languages = {
        latex.extensions = [
            ".tex"
            ".sty"
            ".cls"
            ".Rd"
            ".bbx"
            ".cbx"
        ];
        # latexindent is for .tex; texlab formats .bib itself over LSP.
        bibtex = {
            extensions = [ ".bib" ];
            fmt = [ ];
        };
    };
}
