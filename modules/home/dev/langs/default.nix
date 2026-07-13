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
            roots = lib.mkOption {
                type = lib.types.attrsOf (lib.types.listOf lib.types.str);
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
        assertions = lib.concatMap (
            spec:
            map (lsp: {
                assertion = lsp.only-features == [ ] || lsp.except-features == [ ];
                message = "LSP '${lsp.name}': only-features and except-features are mutually exclusive";
            }) spec.lsp
        ) config.my.user.dev.langs.specs;

        home.packages = allPkgs;
        my.user.dev.langs.specs = dataSpecs;
    };
}
