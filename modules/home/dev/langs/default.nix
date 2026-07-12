# Language tooling. Every *.nix file in this directory is picked up automatically.
#
# Lang files return a typed data spec ({ lang, pkgs, lsp, fmt, file-types, roots }).
# This module validates each spec and translates it to home.packages + editor config.
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

    specOptions = {
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

    evalSpec = raw: (lib.evalModules {
        modules = [ { options = specOptions; } { config = raw; } ];
    }).config;

    rawMods   = lib.mapAttrsToList (n: _: import (dir + "/${n}") { inherit pkgs lib config; }) files;
    dataSpecs = map evalSpec (builtins.filter (m: m ? lang) rawMods);
    oldMods   = builtins.filter (m: !(m ? lang)) rawMods;

    toCmd = list: { command = lib.head list; args = lib.tail list; };

    toLsp = lsp: lib.nameValuePair lsp.name (
        { command = lib.head lsp.cmd; }
        // lib.optionalAttrs (builtins.length lsp.cmd > 1) { args = lib.tail lsp.cmd; }
        // lib.optionalAttrs (lsp.config != {})            { inherit (lsp) config; }
    );

    toLang = spec: langName:
        { name = langName; }
        // { auto-format = true; indent = { tab-width = 4; unit = "    "; }; }
        // lib.optionalAttrs (spec.lsp        != [])             { language-servers = map (l: l.name) spec.lsp; }
        // lib.optionalAttrs (spec.fmt        != null)           { formatter        = toCmd spec.fmt; }
        // lib.optionalAttrs (spec.file-types ? ${langName})     { file-types       = spec.file-types.${langName}; }
        // lib.optionalAttrs (spec.roots      ? ${langName})     { roots            = spec.roots.${langName}; };

    helixOn = config.my.user.dev.editors.helix.enable;

    allLsps  = lib.listToAttrs (lib.concatMap (s: map toLsp s.lsp) dataSpecs);
    allLangs = lib.concatMap (s: map (toLang s) s.lang) dataSpecs;
    allPkgs  = lib.concatMap (s: s.pkgs) dataSpecs;
in
{
    options.my.user.dev.langs.enable =
        tools.opt.mkRiding config.my.user.dev.enable
            "language toolchains (LSPs, formatters, compilers)";

    config = lib.mkIf config.my.user.dev.langs.enable (lib.mkMerge (
        oldMods   # compat: old-format modules; removed after full migration
        ++ [{
            home.packages = allPkgs;
            programs.helix.languages = lib.mkIf helixOn {
                language-server = allLsps;
                language        = allLangs;
            };
        }]
    ));
}
