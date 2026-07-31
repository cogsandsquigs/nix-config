# Path -> feature name. The one definition of which feature owns a file.
#
#   modules/cli/utils/gpg.nix  ->  "cli.utils.gpg"
#   modules/apps/games.nix     ->  "apps.games"
#
# A directory is a namespace level, so it counts toward the feature name and therefore toward the
# option path the file may declare. Used by tools/registry.nix to key the registry and by the
# `feature-paths` check to decide which options a file may declare, so the two cannot disagree about
# what a path means.
{ lib, root }:
let
    modulesDir = "${toString (root + "/modules")}/";
in
path:
let
    segments = lib.splitString "/" (lib.removePrefix modulesDir (toString path));
in
lib.concatStringsSep "." (lib.init segments ++ [ (lib.removeSuffix ".nix" (lib.last segments)) ])
