# agenix rules — COMPUTED, not hand-maintained. `agenix` reads this file to learn which recipients
# each secret is encrypted to. We walk the secrets/ tree and assign every `*.age` file the public
# key of its owning scope (its first two path components, e.g. "users/cogs" or "hosts/home-desktop")
# from ./recipients.nix. So adding a secret = drop the `.age` file in the right dir + (if a new
# scope) add its key to recipients.nix — no per-secret rule edits here.
#
# Attr names are the file paths relative to secrets/ WITH `.age` (what agenix matches on disk);
# `age.secrets.<name>` in the config uses the same path WITHOUT `.age` (see lib/opts.nix secretFile).
#
# Pure `builtins` only (no lib / no <nixpkgs>): this file is evaluated by the agenix CLI, which has
# no guaranteed NIX_PATH, so we avoid `import <nixpkgs>`.
let
    keys = import ./recipients.nix;

    inherit (builtins)
        readDir
        attrNames
        concatMap
        listToAttrs
        match
        elemAt
        filter
        isString
        split
        ;

    # Recursively collect every `*.age` path under `dir`, as strings relative to secrets/ root.
    collect =
        prefix: dir:
        concatMap (
            e:
            let
                rel = prefix + e;
            in
            if (readDir dir).${e} == "directory" then
                collect (rel + "/") (dir + "/${e}")
            else if match ".*\\.age" e != null then
                [ rel ]
            else
                [ ]
        ) (attrNames (readDir dir));

    ageFiles = collect "" ./.;

    # Owning scope = first two path components joined, e.g. "users/cogs/gpg.age" -> "users/cogs".
    ownerOf =
        f:
        let
            parts = filter isString (split "/" f);
        in
        (elemAt parts 0) + "/" + (elemAt parts 1);
in
listToAttrs (
    map (f: {
        name = f;
        value.publicKeys = [ keys.${ownerOf f} ];
    }) ageFiles
)
