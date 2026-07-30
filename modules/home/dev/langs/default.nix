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
            name = lib.mkOption { type = lib.types.str; };
            cmd = lib.mkOption { type = lib.types.nonEmptyListOf lib.types.str; };
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
                default = [ ];
            };
            except-features = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
            };
        };
    };

    # One language served by the enclosing toolchain. Omitted fields inherit the editor's own
    # defaults -- helix ships a builtin definition for nearly every language here, so only
    # deliberate deviations belong in `file-types` and `roots`.
    langDef = lib.types.submodule {
        options = {
            extensions = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = ''
                    File extensions, leading dot kept, for clients that bind servers by extension
                    rather than by language name. Pointless without an `lsp` on the toolchain.
                '';
                example = [ ".ts" ];
                default = [ ];
            };

            file-types = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = "Overrides helix's builtin list for this language, replacing it wholesale.";
                default = [ ];
            };

            roots = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = "Overrides helix's builtin project-root markers for this language.";
                default = [ ];
            };

            language-id = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                description = "LSP language identifier. Null means the language's own name.";
                default = null;
            };
        };
    };

    toolchain = lib.types.submodule {
        options = {
            pkgs = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
            };

            lsp = lib.mkOption {
                type = lib.types.listOf lspSpec;
                default = [ ];
            };

            fmt = lib.mkOption {
                type = lib.types.nullOr (lib.types.nonEmptyListOf lib.types.str);
                default = null;
            };

            # No default: a toolchain serving no language would silently install packages and drop
            # its LSP and formatter on the floor.
            languages = lib.mkOption { type = lib.types.attrsOf langDef; };

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
