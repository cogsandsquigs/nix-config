# modules/ -> { nixos = { <feature> = <module>; }; darwin = { ... }; homeManager = { ... }; }
#
# Replaces the hand-written import lists that used to live in a default.nix per directory. Those could
# lie: a file present but unimported was a silent no-op. A path cannot.
#
# `import-tree` walks the tree and hands each file to `classify`. Its defaults are already the
# convention we want -- .nix files only, and skip anything containing "/_" -- so it needs no
# configuration. `.map` receives the ABSOLUTE path (`.filter` and `.match` would receive the
# root-relative one), which is where a path becomes a feature name.
#
# Naming grammar. A file that does not match it fails the build with its own path:
#
#   <feature>.nix   a feature, as an attrset keyed by class: nixos, darwin, home. Every file is keyed,
#                   single-class ones included, so adding a class later adds a key and never renames a
#                   file. A `let` above the keys shares a body between them.
#   <ns>/default.nix  the feature that owns the folder `<ns>`, keyed the same way. Its own segment names
#                   no level, so `dev/ai/default.nix` is the feature `dev.ai` and sits with the children
#                   it groups.
#   _<anything>     not a module. Shared values, package definitions, data tables, drafts.
#
# Either form of a feature file may be a FUNCTION of the classify-time arguments, so a file that needs
# `tools` for its option constructors states that once at the top instead of once per class key:
# `{ tools, ... }: { nixos = ...; darwin = ...; }`. Only `lib` and `tools` exist there. The
# evaluation-time arguments -- config, pkgs, host, inputs -- do not: classify runs while the registry is
# being built, before any host is evaluated, so a module that needs them opens under its class key.
#
# The reserved key `options` is not a class. It declares the options that EVERY class in the file
# declares, so a feature states them once; it merges with any `options` a class key declares itself.
# The two must be disjoint, which the module system enforces on its own: declaring one option in both
# is "already declared in", naming the file twice.
#
# A block shared by only SOME classes is a `let` above the keys, not this. Only `nixos` and `darwin`
# install the sops CLI, for instance, and a shared block would declare `my.sys.secrets.enable` inside
# the home evaluation as well -- where nothing reads it and `my.sys` has no business existing.
#
# A directory adds a level to the feature name, and a feature may only declare options under the path
# it owns -- see the `feature-paths` check in tools/checks.nix.
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
    # resolve to "cli.utils" (see tools/feature.nix). Plain `deferredModule` merges same-key definitions
    # into one module without complaint, which would leave the feature owned by two files and
    # `feature-paths` comparing against whichever `_file` it saw. `uniq` makes that
    # "is defined multiple times while it's expected to be unique", naming the feature.
    #
    # It fires when a feature's module is DEMANDED, so any host evaluation trips it -- which is what
    # `fleet-eval` does, so `nix flake check` catches it. `nix flake show` does not: listing the
    # registry only forces the attribute names.
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

    # The shared block may be a plain attrset of options or a function of the module arguments, since
    # `tools` and `config` are what an option constructor usually needs.
    asModule =
        value: if lib.isFunction value then args: { options = value args; } else { options = value; };

    # What a feature file gets when it is written as a function. `tools` is the reason the form exists;
    # `lib` comes along because an option constructor usually needs both.
    featureArgs = { inherit lib tools; };

    # callPackage-style application, so `{ tools }:` is as legal as `{ tools, ... }:`. An argument that
    # only exists during host evaluation is the trap this form sets, so it is named as such rather than
    # left to the module system's "called without required argument".
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
# The registry is a module evaluation whose only options are the three classes, so a value that is not
# a module fails as a type error from the module system rather than from hand-written validation. An
# unknown class key never reaches it -- `classify` above throws first, naming the file, which is the
# better message. This is dendritic's `flake.modules.<class>.<name>` without flake-parts: that
# attribute is a flake-parts option, and this is the same thing declared locally.
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
