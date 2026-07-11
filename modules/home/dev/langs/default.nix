# Language tooling. Every *.nix file in this directory is picked up automatically, so adding
# support for a new language is just dropping a file in here — no need to edit this list.
#
# The whole set rides one leaf, `my.user.dev.langs.enable`. Because `imports` can't be gated by an
# option (imports are resolved before config), we DON'T list the lang files in `imports`; instead we
# import-and-merge them here under a single `lib.mkIf`. Each lang file is a plain module returning
# package/config attrs (they all accept `...`), so calling it with the module args and merging the
# results is equivalent to importing it — but now one flag gates every language, no per-file edits.
{
    pkgs,
    lib,
    config,
    tools,
    ...
}:
let
    dir = ./.;
    entries = builtins.readDir dir;
    isLangModule =
        name: type: (type == "regular") && (name != "default.nix") && (lib.hasSuffix ".nix" name);
    langFiles = lib.filterAttrs isLangModule entries;
    langModules = lib.mapAttrsToList (
        name: _type: import (dir + "/${name}") { inherit pkgs lib config; }
    ) langFiles;
in
{
    options.my.user.dev.langs.enable =
        tools.opt.mkRiding config.my.user.dev.enable "language toolchains (LSPs, formatters, compilers)";

    config = lib.mkIf config.my.user.dev.langs.enable (lib.mkMerge langModules);
}
