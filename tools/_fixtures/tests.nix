# Unit tests over tools/, run by `nix flake check` as the `tools-tests` derivation.
#
# `lib.runTests` comes from nixpkgs, so there is no test-framework input. It returns one entry per
# FAILING test and an empty list when everything passes.
#
# The fixtures beside this file are real directory trees, so a test exercises the same `readDir` path
# a host does. Each `bad-*` tree isolates one way of getting a host declaration wrong.
{ pkgs }:
let
    inherit (pkgs) lib;

    opt = import ../opt.nix { inherit lib; };

    fleetOf =
        name:
        import ../fleet.nix {
            inherit lib;
            root = ./. + "/${name}";
        };

    # A schema violation must fail, not pass quietly. `deepSeq` forces the whole attribute set,
    # because the module system defers most of its checking until a value is demanded.
    rejects = name: !(builtins.tryEval (lib.deepSeq (fleetOf name).hosts null)).success;

    ok = fleetOf "ok";

    # Path -> feature name. The paths need not exist: the mapping is string manipulation, and keeping it
    # that way is why one definition can serve both the registry and the `feature-paths` check.
    featureOf =
        relative:
        import ../feature.nix {
            inherit lib;
            root = ./ok;
        } (./ok + "/modules/${relative}");

    # `mkFollowsUsers` takes the option path as a list. A name would miss once a feature moves into a
    # namespace folder, and a missed lookup defaults to `false`, which uninstalls rather than errors.
    followsGames =
        users: (opt.mkFollowsUsers { home-manager.users = users; } [ "apps" "games" ] "games").default;

    results = lib.runTests {
        # -- tools/fleet.nix, accepting a valid declaration ---------------------------------------

        testFleetNameFromDirectory = {
            expr = ok.hosts.alpha.name;
            expected = "alpha";
        };

        testFleetKeepsExplicitPrimaryUser = {
            expr = ok.hosts.alpha.primaryUser;
            expected = "other";
        };

        # -- tools/fleet.nix, rejecting invalid declarations ---------------------------------------

        testFleetRejectsUnknownUser = {
            expr = rejects "bad-user";
            expected = true;
        };

        testFleetRejectsPrimaryUserOutsideUsers = {
            expr = rejects "bad-primary";
            expected = true;
        };

        testFleetRejectsPlatformAgainstClass = {
            expr = rejects "bad-platform";
            expected = true;
        };

        # -- tools/feature.nix ---------------------------------------------------------------------

        testFeatureNameAtTopLevel = {
            expr = featureOf "secrets.nix";
            expected = "secrets";
        };

        testFeatureNameCountsFolders = {
            expr = featureOf "cli/utils/gpg.nix";
            expected = "cli.utils.gpg";
        };

        # A folder's own feature is its default.nix, and that segment names no level -- so this and
        # `cli/utils.nix` would collide, which is why the registry types the feature set as `uniq`.
        testFeatureNameFromFolderDefault = {
            expr = featureOf "dev/ai/default.nix";
            expected = "dev.ai";
        };

        testFeatureNameFromNestedFolderDefault = {
            expr = featureOf "cli/utils/default.nix";
            expected = "cli.utils";
        };

        testFeatureNameRejectsRootDefault = {
            expr = (builtins.tryEval (featureOf "default.nix")).success;
            expected = false;
        };

        # -- tools/opt.nix -------------------------------------------------------------------------

        testOptFollowsUsersReadsAPath = {
            expr = followsGames { someone.my.user.apps.games.enable = true; };
            expected = true;
        };

        testOptFollowsUsersFalseWhenNobodyAsks = {
            expr = followsGames {
                someone.my.user.apps.games.enable = false;
                other = { };
            };
            expected = false;
        };

        testOptEnabledDefaultsOn = {
            expr = (opt.mkEnabled "core feature").default;
            expected = true;
        };

        testOptDisabledDefaultsOff = {
            expr = (opt.mkDisabled "optional feature").default;
            expected = false;
        };

        testOptRidingFollowsParent = {
            expr = (opt.mkRiding false "sub-feature").default;
            expected = false;
        };

    };
in
if results == [ ] then
    pkgs.writeText "tools-tests" "ok"
else
    throw ''
        tools-tests: ${toString (builtins.length results)} failing

          ${lib.concatMapStringsSep "\n  " (
              r:
              "${r.name}: expected ${lib.generators.toPretty { } r.expected} but got ${
                  lib.generators.toPretty { } r.result
              }"
          ) results}
    ''
