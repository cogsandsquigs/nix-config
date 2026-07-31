# The gates. `nix flake check` runs all of them, from any machine in the fleet.
#
# Called once per platform the fleet uses (see tools/default.nix `forAllSystems`), so a check that
# needs a package gets one for the right platform.
#
# Exposes one derivation per check:
#   fleet-eval     -- every host still evaluates, including hosts this machine cannot build
#   typed-options  -- no `my.*` option is loosely typed or undocumented
#   tools-tests    -- unit tests over tools/, via lib.runTests
#   lint           -- statix reports nothing (see ../statix.toml)
{ self, tools }:
pkgs:
let
    inherit (pkgs) lib;

    # Every host's top-level derivation, whatever class the host is.
    toplevels =
        lib.mapAttrs (_: c: c.config.system.build.toplevel) tools.nixosConfigurations
        // lib.mapAttrs (_: c: c.config.system.build.toplevel) tools.darwinConfigurations
        // lib.mapAttrs (_: c: c.activationPackage) tools.homeConfigurations;

    # -- typed-options ---------------------------------------------------------------------------

    # Types that carry no information: they accept anything, so they check nothing.
    looseTypes = [
        "attrs"
        "anything"
        "raw"
        "unspecified"
    ];

    # Options that are free-form on purpose. Enumerated, so the exceptions stay finite and visible.
    allowedLoose = [
        # Passed through verbatim to the editor's own config file, whose schema is not ours.
        "my.user.dev.langs.toolchains.lsp.config"
        # TODO: give this a submodule with the editors we actually support, then drop this entry.
        "my.user.dev.langs.toolchains.editor-specific"
    ];

    # A loose type anywhere inside a type expression counts: `attrsOf attrs` checks its keys and
    # nothing else. `nestedTypes` is how a composite type exposes what it wraps. The depth cap is
    # only there to stop a self-referential type from looping.
    looseType =
        depth: type:
        lib.elem type.name looseTypes
        || (depth > 0 && lib.any (looseType (depth - 1)) (lib.attrValues (type.nestedTypes or { })));

    # Walk an option tree and report every option that is loosely typed or undocumented. Descends
    # into submodules through `getSubOptions`, so fields inside a submodule are covered too.
    #
    # `_module` is skipped because it is the module system's own plumbing: every submodule carries
    # `_module.args` and `_module.specialArgs`, both necessarily free-form, and neither is ours to fix.
    badOptions =
        loc: attrs:
        lib.concatLists (
            lib.mapAttrsToList (
                name: value:
                let
                    here = loc ++ [ name ];
                    shown = lib.showOption here;
                in
                if name == "_module" then
                    [ ]
                else if lib.isOption value then
                    lib.optional (
                        !(lib.elem shown allowedLoose) && (looseType 8 value.type || (value.description or null) == null)
                    ) shown
                    ++ badOptions here (value.type.getSubOptions here)
                else if lib.isAttrs value then
                    badOptions here value
                else
                    [ ]
            ) attrs
        );

    # The same module set is loaded on every class, so one configuration per class covers every
    # option the repo declares.
    someOf = cfgs: lib.optional (cfgs != { }) (lib.head (lib.attrValues cfgs));

    optionRoots = lib.concatMap someOf [
        tools.homeConfigurations
        tools.nixosConfigurations
        tools.darwinConfigurations
    ];

    offenders = lib.unique (lib.concatMap (c: badOptions [ "my" ] (c.options.my or { })) optionRoots);

    # -- reporting -------------------------------------------------------------------------------

    pass = name: pkgs.writeText name "ok";

    fail =
        name: what: items:
        throw ''
            ${name}: ${what}

              ${lib.concatStringsSep "\n  " items}
        '';
in
{
    # Forcing each top-level derivation path evaluates that whole configuration. The string context
    # is discarded, so this never instantiates a derivation for another platform -- which is what
    # lets one command on the work desktop prove the MacBook configuration still evaluates.
    fleet-eval = pkgs.writeText "fleet-eval" (
        lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
                name: drv: "${name} ${builtins.unsafeDiscardStringContext drv.drvPath}"
            ) toplevels
        )
    );

    typed-options =
        if offenders == [ ] then
            pass "typed-options"
        else
            fail "typed-options" "loosely typed or undocumented options" offenders;

    tools-tests = import ./_fixtures/tests.nix { inherit pkgs; };

    # `self` is the flake source, so this sees git-tracked files only -- the same set `nxm` stages
    # before a rebuild. A finding in an unstaged file will not appear here.
    lint = pkgs.runCommand "lint" { nativeBuildInputs = [ pkgs.statix ]; } ''
        cd ${self}
        statix check .
        touch $out
    '';
}
