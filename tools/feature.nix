# Path -> feature name. The one definition of which feature owns a file.
#
#   modules/dev/ai/mcp/gerrit.home.nix  ->  "dev.ai.mcp.gerrit"
#   modules/games.nix                   ->  "games"
#
# A class suffix is not part of the name, so every class of a feature shares one name. Used by
# tools/registry.nix to key the registry and by the `feature-paths` check to decide which options a
# file may declare, so the two cannot disagree about what a path means.
{ lib, root }:
let
    modulesDir = "${toString (root + "/modules")}/";

    classSuffixes = [
        "nixos"
        "darwin"
        "home"
    ];
in
path:
let
    segments = lib.splitString "/" (lib.removePrefix modulesDir (toString path));
    parts = lib.splitString "." (lib.removeSuffix ".nix" (lib.last segments));
    stem = if lib.elem (lib.last parts) classSuffixes then lib.init parts else parts;
in
lib.concatStringsSep "." (lib.init segments ++ stem)
