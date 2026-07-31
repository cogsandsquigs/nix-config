# The gates. `nix flake check` runs all of them, from any machine in the fleet.
#
# Called once per platform the fleet uses (see tools/default.nix `forAllSystems`), so a check that needs
# a package gets one for the right platform.
#
# Exposes one derivation per check:
#   fleet-eval     -- every host still evaluates, including hosts this machine cannot build
#   feature-paths  -- no file declares options outside the feature its path owns
#   typed-options  -- no `my.*` option is loosely typed or undocumented
#   tools-tests    -- unit tests over tools/, via lib.runTests
#   lint           -- statix reports nothing (see ../statix.toml)
{ self, tools }:
pkgs:
let
    inherit (pkgs) lib;

    feature = import ./feature.nix {
        inherit lib;
        inherit (tools) root;
    };

    modulesDir = "${toString (tools.root + "/modules")}/";

    # Every host's top-level derivation, whatever class the host is.
    toplevels =
        lib.mapAttrs (_: c: c.config.system.build.toplevel) tools.nixosConfigurations
        // lib.mapAttrs (_: c: c.config.system.build.toplevel) tools.darwinConfigurations
        // lib.mapAttrs (_: c: c.activationPackage) tools.homeConfigurations;

    # -- the shared option walk ------------------------------------------------------------------

    # Every option declared under `my`, as { loc; opt; }. One walk, two checks read it. Descends into
    # submodules through `getSubOptions`, so fields inside a submodule are covered too.
    #
    # `_module` is skipped because it is the module system's own plumbing: every submodule carries
    # `_module.args` and `_module.specialArgs`, both necessarily free-form, and neither is ours to fix.
    declaredOptions =
        loc: attrs:
        lib.concatLists (
            lib.mapAttrsToList (
                name: value:
                let
                    here = loc ++ [ name ];
                in
                if name == "_module" then
                    [ ]
                else if lib.isOption value then
                    [
                        {
                            loc = here;
                            opt = value;
                        }
                    ]
                    ++ declaredOptions here (value.type.getSubOptions here)
                else if lib.isAttrs value then
                    declaredOptions here value
                else
                    [ ]
            ) attrs
        );

    # The same module set is loaded on every class, so one configuration per class covers every option
    # the repo declares.
    someOf = cfgs: lib.optional (cfgs != { }) (lib.head (lib.attrValues cfgs));

    allOptions = lib.concatMap (c: declaredOptions [ "my" ] (c.options.my or { })) (
        lib.concatMap someOf [
            tools.homeConfigurations
            tools.nixosConfigurations
            tools.darwinConfigurations
        ]
    );

    # -- feature-paths ---------------------------------------------------------------------------

    # `my.<scope>.<feature>...` may only be declared by the file whose path owns <feature>. This is what
    # makes the layout a rule rather than a habit: move a file without renaming its options and the
    # build fails, rename an option without moving its file and the build fails the same way.
    misplaced = lib.concatMap (
        o:
        let
            # Everything after `my.<scope>`, which is what the owning feature's name must prefix.
            optionPath = lib.concatStringsSep "." (lib.drop 2 o.loc);
        in
        lib.concatMap (
            decl:
            let
                owner = feature decl;
            in
            if !(lib.hasPrefix modulesDir decl) then
                [ "${lib.showOption o.loc} is declared outside modules/ (${decl})" ]
            else
                lib.optional (optionPath != owner && !(lib.hasPrefix "${owner}." optionPath))
                    "${lib.showOption o.loc} is declared in ${lib.removePrefix modulesDir decl}, which owns the feature '${owner}'"
        ) (o.opt.declarations or [ ])
    ) allOptions;

    # No check for a shared `options` block overlapping a class key: the module system already rejects
    # a duplicate declaration ("The option `x' in `f' is already declared in `f'"), and it does so
    # before anything here could read the option, so a check of our own would be unreachable.

    # -- typed-options ---------------------------------------------------------------------------

    # Types that carry no information: they accept anything, so they check nothing.
    looseTypes = [
        "attrs"
        "anything"
        "raw"
        "unspecified"
    ];

    # Options that are free-form on purpose. Enumerated, so the exceptions stay finite and visible.
    # Each of these is a foreign schema: the value is handed verbatim to a tool that defines its own
    # keys, so declaring a type here would mean tracking someone else's config format.
    allowedLoose = [
        "my.user.dev.langs.toolchains.lsp.config" # a language server's own settings
        "my.user.dev.langs.toolchains.editor-specific.helix" # helix's own language settings
    ];

    # A loose type anywhere inside a type expression counts: `attrsOf attrs` checks its keys and nothing
    # else. `nestedTypes` is how a composite type exposes what it wraps. The depth cap is only there to
    # stop a self-referential type from looping.
    looseType =
        depth: type:
        lib.elem type.name looseTypes
        || (depth > 0 && lib.any (looseType (depth - 1)) (lib.attrValues (type.nestedTypes or { })));

    untyped = lib.concatMap (
        o:
        let
            shown = lib.showOption o.loc;
        in
        lib.optional (
            !(lib.elem shown allowedLoose) && (looseType 8 o.opt.type || (o.opt.description or null) == null)
        ) shown
    ) allOptions;

    # -- reporting -------------------------------------------------------------------------------

    pass = name: pkgs.writeText name "ok";

    fail =
        name: what: items:
        throw ''
            ${name}: ${what}

              ${lib.concatStringsSep "\n  " (lib.unique items)}
        '';
in
{
    # Forcing each top-level derivation path evaluates that whole configuration. The string context is
    # discarded, so this never instantiates a derivation for another platform -- which is what lets one
    # command on the work desktop prove the MacBook configuration still evaluates.
    fleet-eval = pkgs.writeText "fleet-eval" (
        lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
                name: drv: "${name} ${builtins.unsafeDiscardStringContext drv.drvPath}"
            ) toplevels
        )
    );

    feature-paths =
        if misplaced == [ ] then
            pass "feature-paths"
        else
            fail "feature-paths" "options declared outside the feature their file owns" misplaced;

    typed-options =
        if untyped == [ ] then
            pass "typed-options"
        else
            fail "typed-options" "loosely typed or undocumented options" untyped;

    tools-tests = import ./_fixtures/tests.nix { inherit pkgs; };

    # `self` is the flake source, so this sees git-tracked files only -- the same set `nxm` stages
    # before a rebuild. A finding in an unstaged file will not appear here.
    lint = pkgs.runCommand "lint" { nativeBuildInputs = [ pkgs.statix ]; } ''
        cd ${self}
        statix check .
        touch $out
    '';
}
