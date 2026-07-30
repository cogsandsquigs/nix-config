{ pkgs, ... }: {
    lang = [ "latex" ];

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
            config.texlab = {
                build = {
                    onSave = true;
                    forwardSearchAfter = true;
                };
                forwardSearch = {
                    executable = "???"; # TODO
                    args = [ ]; # TODO: synctex args
                };
                chktex.onEdit = true;
            };
        }
    ];

    extensions = {
        ".tex" = "latex";
        ".sty" = "latex";
        ".cls" = "latex";
        ".bib" = "bibtex";
    };

    fmt = [
        "latexindent"
        "-"
    ];
}
