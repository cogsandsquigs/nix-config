# modules/ -> { nixos = { <feature> = <module>; }; darwin = { ... }; homeManager = { ... }; }
#
# `import-tree` walks the tree and hands each file to `classify`. Its defaults are the convention we
# want -- .nix only, skip anything containing "/_" -- so it takes no configuration. `.map` receives the
# ABSOLUTE path (`.filter` and `.match` get the root-relative one).
#
# Naming grammar. A file that does not match it fails the build with its own path:
#
#   <feature>.nix     a feature, as an attrset keyed by class: nixos, darwin, home. Single-class files
#                     are keyed too, so adding a class later never renames a file.
#   <ns>/default.nix  the feature that owns the folder `<ns>`. That segment names no level, so
#                     `dev/ai/default.nix` is the feature `dev.ai`.
#   _<anything>       not a module. Shared values, package definitions, data tables, drafts.
#
# Either form may be a FUNCTION of the classify-time arguments -- `lib` and `tools`, nothing else, since
# classify runs before any host exists. A module needing config/pkgs/host/inputs opens under its class
# key instead.
#
# The reserved key `options` declares what EVERY class in the file declares. It must be disjoint from any
# `options` a class key declares. The module system enforces that itself ("already declared in"). A block
# shared by only SOME classes is a `let` above the keys, not this -- a shared block would declare
# `my.sys.*` inside the home evaluation, where nothing can read it.
#
# A directory adds a level to the feature name, and a feature may only declare options under the path it
# owns -- see the `feature-paths` check in tools/checks.nix.
{
    lib,
    importTree,
    root,
    tools,
}:
let
    # Class key -> the module system's own name for that class.
    classes = {
        nixos = "nixos";
        darwin = "darwin";
        home = "homeManager";
    };

    feature = import ./feature.nix { inherit lib root; };

    # `uniq`, because two paths CAN name one feature: `cli/utils.nix` and `cli/utils/default.nix` both
    # resolve to "cli.utils". Plain `deferredModule` would merge them silently, leaving the feature owned
    # by two files. `uniq` makes it "is defined multiple times", naming the feature.
    #
    # It fires when a feature's module is DEMANDED, so `fleet-eval` catches it but `nix flake show` does
    # not -- listing the registry only forces the attribute names.
    mkFeatureOption =
        what:
        lib.mkOption {
            type = lib.types.attrsOf (lib.types.uniq lib.types.deferredModule);
            default = { };
            description = "Features contributing ${what} modules, keyed by feature name.";
        };

    # `_file` stays the bare path: `feature-paths` compares option `declarations` against it. An inline
    # module in `imports` inherits its parent's `_file`, so the shared options block reports the same
    # path its class halves do.
    entry = path: class: modules: {
        _class = class;
        _file = toString path;
        imports = modules;
    };

    # The shared block may be a plain attrset of options or a function of the module arguments.
    asModule =
        value: if lib.isFunction value then args: { options = value args; } else { options = value; };

    # What a feature file gets when it is written as a function.
    featureArgs = { inherit lib tools; };

    # callPackage-style application, so `{ tools }:` is as legal as `{ tools, ... }:`. Asking for an
    # evaluation-time argument is the trap this form sets, so it is named rather than left to the module
    # system's "called without required argument".
    #
    # `functionArgs` is `{ }` for both `{ ... }:` and `x:`, which is why that case takes the whole set.
    apply =
        path: f:
        let
            wanted = lib.functionArgs f;
            unknown = lib.attrNames (removeAttrs wanted (lib.attrNames featureArgs));
        in
        if unknown != [ ] then
            throw ''
                ${toString path}
                A feature function takes ${lib.concatStringsSep ", " (lib.attrNames featureArgs)}; this one asks for ${lib.concatStringsSep ", " unknown}.
                The evaluation-time arguments (config, pkgs, host, inputs) belong to a module under a class
                key -- this runs while the registry is built, before any host exists.
            ''
        else if wanted == { } then
            f featureArgs
        else
            f (builtins.intersectAttrs wanted featureArgs);

    classify =
        path:
        let
            imported = import path;
            raw = if lib.isFunction imported then apply path imported else imported;
            name = feature path;
            byClass = removeAttrs raw [ "options" ];
            shared = lib.optional (raw ? options) (asModule raw.options);
        in
        if byClass == { } then
            throw ''
                ${toString path}
                A feature declares at least one class key (${lib.concatStringsSep ", " (lib.attrNames classes)}).
                `options` alone declares options that nothing can ever read.
            ''
        else
            {
                modules = lib.mapAttrs' (
                    key: module:
                    let
                        class =
                            classes.${key} or (throw ''
                                ${toString path}
                                Unknown class key "${key}". Expected any of ${lib.concatStringsSep ", " (lib.attrNames classes)}, or the reserved key "options".
                                A plain module lands here too: put its body under the class it belongs to
                                ({ home = { pkgs, ... }: { ... }; }), or prefix the filename with "_" if it is
                                not a module at all.
                            '');
                    in
                    lib.nameValuePair class { ${name} = entry path class (shared ++ [ module ]); }
                ) byClass;
            };
in
# A module evaluation whose only options are the three classes, so a value that is not a module fails as
# a type error rather than through hand-written validation. An unknown class key never reaches it --
# `classify` throws first, naming the file. This is dendritic's `flake.modules.<class>.<name>` declared
# locally instead of through flake-parts.
(lib.evalModules {
    class = "fleet";

    modules = [
        {
            options.modules = {
                nixos = mkFeatureOption "NixOS";
                darwin = mkFeatureOption "nix-darwin";
                homeManager = mkFeatureOption "home-manager";
            };
        }

        ((importTree.map classify) (root + "/modules"))
    ];
}).config.modules
