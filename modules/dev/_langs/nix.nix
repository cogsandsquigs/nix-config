{ pkgs, lib, ... }:
let
    statixTool = [
        {
            # Bare `statix`, never `${pkgs.statix}/bin/statix`: `builtins.toFile` rejects a string
            # with store references. It resolves from `pkgs` below, on PATH.
            lint-command = "statix check --stdin --format=errfmt";
            lint-ignore-exit-code = true;
            lint-stdin = true;
            lint-after-open = true;
            # FILE>LINE:COL:TYPE:CODE:MESSAGE. statix names the buffer `<stdin>`; efm rewrites that
            # to the real path, and only for the names it whitelists, of which `<stdin>` is one.
            lint-formats = [ "%f>%l:%c:%t:%n:%m" ];
        }
    ];

    # efm runs the linter with cwd set to whichever of these markers it finds, and statix looks for
    # statix.toml up from cwd -- so the editor's lints are the `lint` gate's lints, same config.
    efmConfig = builtins.toFile "efm-config.yaml" (
        lib.generators.toYAML { } {
            version = 2;
            root-markers = [
                ".git/"
                "flake.nix"
            ];
            lint-debounce = "1s";
            languages.nix = statixTool;
        }
    );
in
{
    pkgs = with pkgs; [
        nixfmt # Official/default formatter (per-file, used by the editor)
        treefmt # Whole-tree formatter (alt) -- driven by ./treefmt.toml; also what `nix fmt` runs
        nixd # Official community Nix LSP
        nil # Nix LSP, live fallback -- see the note on `lsp` below
        statix # Nix linter -- the `lint` gate's checker, surfaced live through efm-langserver below
        efm-langserver
    ];

    # nixd AND nil both run on every .nix file, deliberately (efm, third, only carries statix's
    # diagnostics). `languages.nix` declares no `lsp` of its own,
    # so it inherits this whole list, and `nixd` comes first because it is the better of the two. The
    # redundancy IS the feature: when `nixd` dies mid-session, `nil` is already attached and keeps
    # answering, instead of leaving the file with no server at all. Do not narrow this to one server.
    lsp = [
        {
            name = "nixd";
            cmd = [ "nixd" ];
        }
        {
            name = "nil";
            cmd = [
                "nil"
                "--stdio"
            ];
            config.nil.flake.autoArchive = true;
        }
        {
            name = "efm-langserver-nix";
            cmd = [
                "efm-langserver"
                "-c"
                "${efmConfig}"
            ];
            only-features = [ "diagnostics" ];
        }
    ];

    fmt = [
        "nixfmt"
        "--width=100"
        "--indent=4"
        "--quiet"
        "--strict"
        "-"
    ];

    languages.nix.extensions = [ ".nix" ];
}
