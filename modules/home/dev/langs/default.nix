# Language tooling. Every *.nix file in this directory is picked up automatically.
#
# Lang files return a typed data spec ({ lang, pkgs, lsp, fmt, file-types, roots }).
# Validated specs are exposed via my.user.dev.langs.specs for editor modules to consume.
# Old-format modules (returning NixOS config directly) are merged via the compat path.
{
    pkgs,
    lib,
    config,
    tools,
    ...
}:
let
    dir   = ./.;
    files = lib.filterAttrs
        (n: t: t == "regular" && n != "default.nix" && lib.hasSuffix ".nix" n)
        (builtins.readDir dir);

    lspSpec = lib.types.submodule {
        options = {
            name   = lib.mkOption { type = lib.types.str; };
            cmd    = lib.mkOption { type = lib.types.nonEmptyListOf lib.types.str; };
            config = lib.mkOption { type = lib.types.attrs; default = {}; };
        };
    };

    langSpec = lib.types.submodule {
        options = {
            lang       = lib.mkOption { type = lib.types.nonEmptyListOf lib.types.str; };
            pkgs       = lib.mkOption { type = lib.types.listOf lib.types.package; default = []; };
            lsp        = lib.mkOption { type = lib.types.listOf lspSpec; default = []; };
            fmt        = lib.mkOption {
                type    = lib.types.nullOr (lib.types.nonEmptyListOf lib.types.str);
                default = null;
            };
            file-types = lib.mkOption {
                type    = lib.types.attrsOf (lib.types.listOf lib.types.str);
                default = {};
            };
            roots      = lib.mkOption {
                type    = lib.types.attrsOf (lib.types.listOf lib.types.str);
                default = {};
            };
        };
    };

    rawMods   = lib.mapAttrsToList (n: _: import (dir + "/${n}") { inherit pkgs lib config; }) files;
    dataSpecs = builtins.filter (m: m ? lang) rawMods;
    oldMods   = builtins.filter (m: !(m ? lang)) rawMods;

    allPkgs = lib.concatMap (s: s.pkgs or []) dataSpecs;
in
{
    options.my.user.dev.langs = {
        enable = tools.opt.mkRiding config.my.user.dev.enable
            "language toolchains (LSPs, formatters, compilers)";
        specs  = lib.mkOption {
            type     = lib.types.listOf langSpec;
            default  = [];
            internal = true;
        };
    };

    config = lib.mkIf config.my.user.dev.langs.enable (lib.mkMerge (
        oldMods   # compat: old-format modules; removed after full migration
        ++ [{
            home.packages              = allPkgs;
            my.user.dev.langs.specs    = dataSpecs;
        }]
    ));
}
