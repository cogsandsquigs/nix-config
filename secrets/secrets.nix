# agenix rules — COMPUTED, not hand-maintained. `agenix` reads this to learn who each secret is
# encrypted to. We walk the tree and assign every `*.age` file the recipients named by its AUDIENCE
# folder — its first path segment — resolved against ./recipients.nix by one rule:
#
#   audience contains "@"  → an exact identity ("<user>@<host>")  → that one key
#   audience has no "@"    → a bare user ("<user>")               → all keys "<user>@*"
#
# So `secrets/cogs@home-desktop/gpg.age` goes to just that machine, while `secrets/cogs/vpn.age`
# goes to every cogs machine. Adding a secret = drop the `.age` in the right folder (+ a new key in
# recipients.nix if it's a new identity). No per-secret rule edits here.
#
# Attr names are the paths relative to secrets/ WITH `.age` (what agenix matches on disk);
# `age.secrets.<name>` in the config uses the same path WITHOUT `.age` (see lib/opts.nix).
#
# Pure `builtins` only (no lib / no <nixpkgs>): agenix evaluates this with no guaranteed NIX_PATH.
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

    # First path segment = the audience folder.
    audience = f: elemAt (filter isString (split "/" f)) 0;

    recipients =
        a:
        if match ".*@.*" a != null then
            [ keys.${a} ] # "<user>@<host>" — one identity
        else
            map (n: keys.${n}) (filter (n: match "${a}@.*" n != null) (attrNames keys)); # "<user>" — all machines
in
listToAttrs (
    map (f: {
        name = f;
        value.publicKeys = recipients (audience f);
    }) (collect "" ./.)
)
