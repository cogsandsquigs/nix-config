{
    description = "The typed fleet, the feature registry, the builders and the gates.";

    # No inputs. Everything this library needs -- nixpkgs, nix-darwin, home-manager, import-tree --
    # is handed to `mkTools` by the caller, along with the flake root the config tree lives under.
    # That is what lets the parent lock it as `path:./lib` with nothing to `follows`, and what
    # keeps a `nix flake update` in the parent from touching this file.
    #
    # This is a named interface, not a sandbox: `path:./lib` inside a git tree is fetched as the
    # parent repo with `dir=lib`, so a `..` path literal here still resolves. Keep paths inside
    # `lib/`, or take them from the caller's `root`, because nothing will stop you otherwise.
    outputs = _: {
        lib = {
            mkTools = import ./tools;
            mkChecks = import ./tools/checks.nix;
        };
    };
}
