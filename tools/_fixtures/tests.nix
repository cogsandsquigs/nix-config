# Unit tests over tools/, run by `nix flake check` as the `tools-tests` derivation.
#
# `lib.runTests` comes from nixpkgs, so there is no test-framework input. It returns one entry per
# FAILING test and an empty list when everything passes.
#
# The fixtures beside this file are real directory trees, so a test exercises the same `readDir` path
# a host does. Each `bad-*` tree isolates one way of getting a host declaration wrong.
{ pkgs }:
let
    lib = pkgs.lib;

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

    results = lib.runTests {
        # -- tools/fleet.nix, accepting a valid declaration ---------------------------------------

        testFleetFindsUsers = {
            expr = ok.users;
            expected = [
                "other"
                "someone"
            ];
        };

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

        # -- tools/opt.nix -------------------------------------------------------------------------

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

        testOptRequiresHoldsWhenUnused = {
            expr =
                (opt.requires {
                    when = false;
                    needs = false;
                    message = "A needs B";
                }).assertion;
            expected = true;
        };

        testOptRequiresFailsWhenUnmet = {
            expr =
                (opt.requires {
                    when = true;
                    needs = false;
                    message = "A needs B";
                }).assertion;
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
