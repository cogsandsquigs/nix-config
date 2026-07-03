# Language tooling. Every *.nix file in this directory is imported automatically, so adding
# support for a new language is just dropping a file in here — no need to edit this list.
{ lib, ... }:
let
    dir = ./.;
    entries = builtins.readDir dir;
    isLangModule = name: type: (type == "regular") && (name != "default.nix") && (lib.hasSuffix ".nix" name);
    langFiles = lib.filterAttrs isLangModule entries;
in
{
    imports = lib.mapAttrsToList (name: _type: dir + "/${name}") langFiles;
}
