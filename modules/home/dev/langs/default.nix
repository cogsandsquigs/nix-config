# Language tooling. Every *.nix file in this directory is picked up automatically.
#
# Each file returns a toolchain -- packages, LSPs, formatter -- plus the table of languages that
# toolchain serves ({ pkgs, lsp, fmt, editor-specific, languages }), or a list of toolchains when
# one file covers languages needing different servers. Validated toolchains are exposed via
# my.user.dev.langs.toolchains for editor modules to consume.
{
    pkgs,
    lib,
    config,
    tools,
    ...
}:
let
    dir = ./.;
    files = lib.filterAttrs (n: t: t == "regular" && n != "default.nix" && lib.hasSuffix ".nix" n) (
        builtins.readDir dir
    );

    lspSpec = lib.types.submodule {
        options = {
            name = lib.mkOption {
                type = lib.types.str;
                description = ''
                    Identifier for this server: how a language's `lsp` refers to it, and its key in
                    the editor's server table. Reusing helix's builtin name for the same server
                    makes this entry override that builtin instead of adding a second copy.
                '';
                example = "gopls";
            };

            cmd = lib.mkOption {
                type = lib.types.nonEmptyListOf lib.types.str;
                description = ''
                    Command, then its arguments. Resolved on PATH at launch, so the binary has to
                    come from a `pkgs` entry on some enabled toolchain.
                '';
                example = [
                    "taplo"
                    "lsp"
                    "stdio"
                ];
            };

            config = lib.mkOption {
                type = lib.types.attrs;
                description = ''
                    Server config, passed through verbatim. Setting it replaces helix's builtin
                    `config` for that server wholesale (its merge bottoms out at this depth), so
                    omit it to inherit the builtin rather than restating it.
                '';
                default = { };
            };
            only-features = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = ''
                    Take just these helix features from this server and ignore the rest, for a
                    server kept around to do one job -- a linter contributing diagnostics only.
                    Empty takes everything. Mutually exclusive with `except-features` (asserted).
                '';
                example = [ "diagnostics" ];
                default = [ ];
            };

            except-features = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = ''
                    Take every helix feature from this server apart from these. Empty takes
                    everything. Mutually exclusive with `only-features` (asserted).
                '';
                example = [ "format" ];
                default = [ ];
            };
        };
    };

    # One language served by the enclosing toolchain. Everything here is optional: helix ships a
    # builtin definition for nearly every language, and an omitted field inherits it.
    langDef = lib.types.submodule {
        options = {
            extensions = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = ''
                    Extensions this language owns, each keeping its leading dot (asserted). For
                    clients that bind a server to a file by extension instead of by language name;
                    helix is not one of them, it brings its own matching. Values mirror the plain
                    entries of helix's builtin file types for the language. Files identified by their
                    whole name rather than a suffix (`go.mod`, `.bashrc`) cannot be listed at all:
                    a dotless key rejects Claude's whole config, and a dot-led one never matches,
                    so helix's builtin globs are the only thing that catches them. Does nothing
                    unless the language resolves to at least one server.
                '';
                example = [ ".ts" ];
                default = [ ];
            };

            roots = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = ''
                    Filenames marking a project root, which decides the workspace a language server
                    is handed. Replaces helix's builtin markers wholesale, so leave empty to inherit
                    them. Keep any marker tight: one that matches ordinary source files (`*.hs`)
                    turns every subdirectory into its own project and gives the server a workspace
                    too small to resolve imports.
                '';
                example = [ "Cargo.toml" ];
                default = [ ];
            };

            language-id = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                description = ''
                    Identifier a client reports for this language over LSP, in
                    `textDocument/didOpen`; some servers select a parser or feature set from it.
                    Null means the language's own name, which is correct nearly always -- set it
                    only where the protocol id genuinely differs, as with `jsx` and
                    `javascriptreact`. Helix carries its own equivalent, so this reaches only the
                    extension-binding clients.
                '';
                example = "typescriptreact";
                default = null;
            };

            lsp = lib.mkOption {
                type = lib.types.nullOr (lib.types.listOf lib.types.str);
                description = ''
                    Which of the toolchain's servers serve this language, by name. Null inherits all
                    of them, `[ ]` leaves the language with none, and a non-empty list selects a
                    subset. Every name must appear in the toolchain's own `lsp` (asserted), so a
                    typo fails the build instead of quietly dropping a server.
                '';
                example = [ "gopls" ];
                default = null;
            };

            fmt = lib.mkOption {
                type = lib.types.nullOr (lib.types.listOf lib.types.str);
                description = ''
                    Formatter for this language: command first, then arguments. Null inherits the
                    toolchain's `fmt`, `[ ]` removes it and leaves formatting to whichever server
                    offers it, and a non-empty list overrides. Use `[ ]` where the toolchain's
                    formatter would corrupt the file -- `gofmt` on a `go.mod`, say.
                '';
                default = null;
            };
        };
    };

    toolchain = lib.types.submodule {
        options = {
            pkgs = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                description = ''
                    Everything this toolchain installs: compilers, language servers, formatters,
                    linters, debuggers. Merged into `home.packages` across all toolchains, so two
                    toolchains naming the same package is harmless.
                '';
                default = [ ];
            };

            lsp = lib.mkOption {
                type = lib.types.listOf lspSpec;
                description = ''
                    Language servers this toolchain provides. Every one of its languages uses all of
                    them unless that language's own `lsp` narrows the set. Declaring a server here
                    replaces helix's builtin entry of the same name, so the list a language ends up
                    with is this one, not this one merged with the builtin.
                '';
                default = [ ];
            };

            fmt = lib.mkOption {
                type = lib.types.nullOr (lib.types.nonEmptyListOf lib.types.str);
                description = ''
                    Default formatter for every language here: command first, then arguments. Null
                    leaves formatting to the language servers. A single language overrides this, or
                    opts out of it, with its own `fmt`.
                '';
                default = null;
            };

            # No default: a toolchain serving no language would install its packages and then drop
            # its servers and formatter on the floor.
            languages = lib.mkOption {
                type = lib.types.attrsOf langDef;
                description = ''
                    Languages this toolchain serves, keyed by the editor's name for each. The keys
                    are the only declaration of which languages a file covers, and no two toolchains
                    may claim the same one (asserted).
                '';
            };

            editor-specific = lib.mkOption {
                type = lib.types.attrsOf lib.types.attrs;
                description = "Editor-specific language configuration. Will be merged with the other language configuration (e.g. under `\"[<lang>]\": { ... }` in vscode)";
                example = {
                    helix = {
                        auto-format = false;
                    };
                    vscode = {
                        formatOnSave = false;
                    };
                };
                default = { };
            };
        };
    };

    allResults = lib.mapAttrsToList (n: _: import (dir + "/${n}") { inherit pkgs lib config; }) files;
    dataToolchains = lib.concatMap (m: if builtins.isList m then m else [ m ]) allResults;

    allPkgs = lib.concatMap (t: t.pkgs or [ ]) dataToolchains;
in
{
    options.my.user.dev.langs = {
        enable = tools.opt.mkRiding config.my.user.dev.enable "language toolchains (LSPs, formatters, compilers)";
        toolchains = lib.mkOption {
            type = lib.types.listOf toolchain;
            description = ''
                Every toolchain in this directory, flattened and validated. Internal: the read side
                of the contract between the lang files and the editor modules that translate them.
                Nothing outside `modules/home/dev` should set or read it.
            '';
            default = [ ];
            internal = true;
        };
    };

    config = lib.mkIf config.my.user.dev.langs.enable {
        assertions =
            let
                toolchains = config.my.user.dev.langs.toolchains;
                langNames = lib.concatMap (t: lib.attrNames t.languages) toolchains;
            in
            lib.concatMap (
                t:
                map (lsp: {
                    assertion = lsp.only-features == [ ] || lsp.except-features == [ ];
                    message = "LSP '${lsp.name}': only-features and except-features are mutually exclusive";
                }) t.lsp
            ) toolchains
            ++ lib.concatMap (
                t:
                lib.concatMap (
                    name:
                    map (ext: {
                        assertion = lib.hasPrefix "." ext;
                        message = "language '${name}': extension '${ext}' must keep its leading dot";
                    }) t.languages.${name}.extensions
                ) (lib.attrNames t.languages)
            ) toolchains
            ++ lib.concatMap (
                t:
                let
                    known = map (l: l.name) t.lsp;
                in
                lib.concatMap (
                    name:
                    map (n: {
                        assertion = lib.elem n known;
                        message = "language '${name}': lsp '${n}' is not one of its toolchain's servers (${lib.concatStringsSep ", " known})";
                    }) (if t.languages.${name}.lsp == null then [ ] else t.languages.${name}.lsp)
                ) (lib.attrNames t.languages)
            ) toolchains
            ++ [
                {
                    assertion = langNames == lib.unique langNames;
                    message =
                        "language defined by more than one toolchain: "
                        + lib.concatStringsSep ", " (
                            lib.unique (lib.filter (n: lib.count (m: m == n) langNames > 1) langNames)
                        );
                }
            ];

        home.packages = allPkgs;
        my.user.dev.langs.toolchains = dataToolchains;
    };
}
