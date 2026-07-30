# Language tooling. Every *.nix file in this directory is picked up automatically.
#
# Lang files return either a typed data spec ({ lang, pkgs, lsp, fmt, file-types, roots })
# or a list of specs (for files that configure multiple languages with different LSPs).
# Validated specs are exposed via my.user.dev.langs.specs for editor modules to consume.
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

    langSpec = lib.types.submodule {
        options = {
            lang = lib.mkOption { type = lib.types.nonEmptyListOf lib.types.str; };

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

            file-types = lib.mkOption {
                type = lib.types.attrsOf (lib.types.listOf lib.types.str);
                default = { };
            };

            extensions = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                description = ''
                    File extension (leading dot kept) -> LSP language identifier. For clients that
                    bind servers by extension rather than by language name -- helix reads its own
                    `file-types` instead, so the two lists overlap without being derivable from
                    each other (`.prettierrc` is a filename, and bash's id is `shellscript`).
                '';
                example = {
                    ".ts" = "typescript";
                    ".tsx" = "typescriptreact";
                };
                default = { };
            };

            roots = lib.mkOption {
                type = lib.types.attrsOf (lib.types.listOf lib.types.str);
                default = { };
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
    dataSpecs = lib.concatMap (m: if builtins.isList m then m else [ m ]) allResults;

    allPkgs = lib.concatMap (s: s.pkgs or [ ]) dataSpecs;
in
{
    options.my.user.dev.langs = {
        enable = tools.opt.mkRiding config.my.user.dev.enable "language toolchains (LSPs, formatters, compilers)";
        specs = lib.mkOption {
            type = lib.types.listOf langSpec;
            default = [ ];
            internal = true;
        };
    };

    config = lib.mkIf config.my.user.dev.langs.enable {
        assertions =
            lib.concatMap (
                spec:
                map (lsp: {
                    assertion = lsp.only-features == [ ] || lsp.except-features == [ ];
                    message = "LSP '${lsp.name}': only-features and except-features are mutually exclusive";
                }) spec.lsp
            ) config.my.user.dev.langs.specs
            ++ lib.concatMap (
                spec:
                map (ext: {
                    assertion = lib.hasPrefix "." ext;
                    message = "lang '${lib.head spec.lang}': extension '${ext}' must keep its leading dot";
                }) (lib.attrNames spec.extensions)
            ) config.my.user.dev.langs.specs;

        home.packages = allPkgs;
        my.user.dev.langs.specs = dataSpecs;
    };
}
