# The single skills registry. Everything about skills lives here: the in-repo
# skills under ./local (grouped by which harnesses get them), the two pinned
# third-party sets, and the `context` instructions both harnesses ride. Each
# harness imports this once and takes the dir it wants.
#
# Name collisions are not resolved here: pi warns and keeps the first it finds,
# at run time.
{ lib, pkgs, ... }:
let
    # A dir of skill folders as name -> folder.
    # Symlinked skill folders (the mattpocock buckets) read as "symlink".
    scan =
        d:
        lib.mapAttrs (n: _: d + "/${n}") (
            lib.filterAttrs (_: t: t == "directory" || t == "symlink") (builtins.readDir d)
        );

    mattpocock = import ./mattpocock.nix { inherit pkgs; };
    pins = lib.foldl' (a: b: a // b) { } (map scan mattpocock.promoted);
    official = lib.foldl' (a: b: a // b) { } (
        map scan (import ./claude-official.nix { inherit pkgs; })
    );

    localAll = scan ./local/all;
    localClaude = scan ./local/claude;

    assemble =
        attrs:
        pkgs.runCommand "skills" { } (
            "mkdir -p $out\n"
            + lib.concatStringsSep "\n" (lib.mapAttrsToList (n: d: "ln -s ${d} $out/${n}") attrs)
        );
in
{
    skills = {
        claude = assemble (pins // official // localAll // localClaude);
        pi = assemble (pins // official // localAll);
    };
}
