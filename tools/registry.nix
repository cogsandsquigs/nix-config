# modules/ -> { nixos = { <feature> = <module>; }; darwin = { ... }; homeManager = { ... }; }
#
# Replaces the hand-written import lists that used to live in a default.nix per directory. Those could
# lie: a file present but unimported was a silent no-op. A path cannot.
#
# `import-tree` walks the tree and hands each file to `classify`. Its defaults are already the
# convention we want -- .nix files only, and skip anything containing "/_" -- so it needs no
# configuration. `.map` receives the ABSOLUTE path (`.filter` and `.match` would receive the
# root-relative one), which is where a path becomes a class and a feature name.
#
# Naming grammar. A file that does not match it fails the build with its own path:
#
#   <feature>.nix           a feature spanning classes: an attrset keyed by class, so one file owns
#                           every class of the feature and can share a body between them with a `let`.
#   <feature>.<class>.nix   a single-class feature: a plain module. <class> is nixos, darwin or home.
#   _<anything>             not a module. Shared values, package definitions, data tables, drafts.
#
# A directory adds a level to the feature name, and a feature may only declare options under the path
# it owns -- see the `feature-paths` check in tools/checks.nix.
{
    lib,
    importTree,
    root,
}:
let
    # Class key and filename suffix -> the module system's own name for that class.
    classes = {
        nixos = "nixos";
        darwin = "darwin";
        home = "homeManager";
    };

    feature = import ./feature.nix { inherit lib root; };

    mkFeatureOption =
        what:
        lib.mkOption {
            type = lib.types.attrsOf lib.types.deferredModule;
            default = { };
            description = "Features contributing ${what} modules, keyed by feature name.";
        };

    # `_file` stays the bare path: `feature-paths` compares option `declarations` against it.
    entry = path: class: module: {
        _class = class;
        _file = toString path;
        imports = [ module ];
    };

    classify =
        path:
        let
            fileName = lib.last (lib.splitString "/" (toString path));
            parts = lib.splitString "." (lib.removeSuffix ".nix" fileName);
            suffix = classes.${lib.last parts} or null;
            name = feature path;
        in
        if suffix != null then
            { modules.${suffix}.${name} = entry path suffix path; }
        else
            let
                byClass = import path;
            in
            if lib.isFunction byClass then
                throw ''
                    ${toString path}
                    A feature spanning classes is an attrset keyed by class, not a function. Put the
                    class in the filename (<feature>.<class>.nix) if this is a single-class module, or
                    prefix the name with "_" if it is not a module at all.
                ''
            else
                {
                    modules = lib.mapAttrs' (
                        key: module:
                        let
                            class =
                                classes.${key} or (throw ''
                                    ${toString path}
                                    Unknown class key "${key}". Expected any of ${lib.concatStringsSep ", " (lib.attrNames classes)}.
                                '');
                        in
                        lib.nameValuePair class { ${name} = entry path class module; }
                    ) byClass;
                };
in
# The registry is a module evaluation whose only options are the three classes, so the module system --
# not this file -- rejects an unknown class ("option does not exist") and a value that is not a module
# (a type error). This is dendritic's `flake.modules.<class>.<name>` without flake-parts: that
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
