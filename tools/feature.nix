# Path -> feature name. The one definition of which feature owns a file.
#
#   modules/cli/utils/gpg.nix      ->  "cli.utils.gpg"
#   modules/apps/games.nix         ->  "apps.games"
#   modules/cli/utils/default.nix  ->  "cli.utils"
#
# A directory is a namespace level, so it counts toward the feature name and therefore toward the
# option path the file may declare. A folder's own feature is its `default.nix`, matching what that
# name already means in `hosts/<host>/` and in `tools/` -- the thing the folder IS. That segment names
# no level of its own, so `cli/utils.nix` and `cli/utils/default.nix` would be two paths for one
# feature; `tools/registry.nix` types the registry so the collision is a build error rather than a
# silent merge.
#
# Used by tools/registry.nix to key the registry and by the `feature-paths` check to decide which
# options a file may declare, so the two cannot disagree about what a path means.
{ lib, root }:
let
    modulesDir = "${toString (root + "/modules")}/";
in
path:
let
    segments = lib.splitString "/" (lib.removePrefix modulesDir (toString path));
    named = lib.init segments ++ [ (lib.removeSuffix ".nix" (lib.last segments)) ];
    name = if lib.last named == "default" then lib.init named else named;
in
if name == [ ] then
    throw ''
        ${toString path}
        A feature needs a name. `modules/default.nix` owns no folder, so there is no namespace for it
        to be the default of -- give the file the feature's own name instead.
    ''
else
    lib.concatStringsSep "." name
