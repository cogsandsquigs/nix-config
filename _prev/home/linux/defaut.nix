{ pkgs, lib, ... }:
{
    imports =
        let
            inherit (lib.fileset) toList difference fileFilter;
        in
        toList (difference (fileFilter (file: file.hasExt "nix") ./.) ./default.nix);

}
