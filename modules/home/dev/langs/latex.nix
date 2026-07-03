{ pkgs, ... }: {
    home.packages = with pkgs; [
        (texlive.withPackages (
            ps: with ps; [
                latex
                latexmk
                pdftex
            ]
        ))
    ];
}
