{ pkgs, ... }: {
    pkgs = with pkgs; [
        ocaml
        dune # Build system
        opam # Package manager
        ocamlformat # Formatter
        ocamlPackages.ocaml-lsp # LSP -- bundles its own merlin, so no separate merlin package
        ocamlPackages.utop # REPL
        ocamlPackages.odoc # Doc generator
    ];

    lsp = [
        {
            name = "ocamllsp";
            cmd = [ "ocamllsp" ];
            config = {
                codelens.enable = true;
                extendedHover.enable = true;
                duneDiagnostics.enable = true;
                merlinJumpCodeActions.enable = true;
                inlayHints = {
                    hintFunctionParams = true;
                    hintLetBindings = true;
                    hintPatternVariables = true;
                };
            };
        }
    ];

    # Without --enable-outside-detected-project ocamlformat prints the buffer back unchanged, and
    # exits 0, for anything not under a project root. No style flags: those beat a project's
    # .ocamlformat rather than deferring to it.
    fmt = [
        "ocamlformat"
        "--enable-outside-detected-project"
        "--name=%{buffer_name}" # Picks implementation vs interface parsing
        "-"
    ];

    # ocamlformat emits 2-space indentation and has no knob for it, so the repo-wide 4 would fight
    # every save.
    editor-specific.helix.indent = {
        tab-width = 2;
        unit = "  ";
    };

    languages = {
        ocaml.extensions = [ ".ml" ];
        ocaml-interface.extensions = [ ".mli" ];
    };
}
