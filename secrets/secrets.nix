# agenix rules. `agenix` reads this to learn who each secret is encrypted to; every secret you want
# to create/edit MUST have an entry here first (agenix errors on an unknown file). We keep the
# bookkeeping to a minimum: you DECLARE a secret by adding its "location/name" to `declared` below,
# and its recipients are worked out automatically from the AUDIENCE (the location's first path
# segment) against ./recipients.nix by one rule:
#
#   audience contains "@"  → an exact identity ("<user>@<host>")  → that one key
#   audience has no "@"    → a bare user ("<user>")               → all keys "<user>@*"
#
# So `cogs@home-desktop/gpg` goes to just that machine; `cogs/vpn` goes to every cogs machine.
# Adding a secret = one line here (+ a new key in recipients.nix if it's a new identity).
#
# Attr names are the paths relative to secrets/ WITH `.age` (what agenix matches on disk);
# `age.secrets.<name>` in the config uses the same path WITHOUT `.age` (see lib/opts.nix).
#
# Pure `builtins` only (no lib / no <nixpkgs>): agenix evaluates this with no guaranteed NIX_PATH.
let
    keys = import ./recipients.nix;

    inherit (builtins)
        match
        elemAt
        filter
        isString
        split
        attrNames
        map
        listToAttrs
        ;

    # First path segment = the audience folder.
    audience = f: elemAt (filter isString (split "/" f)) 0;

    recipientsFor =
        a:
        if match ".*@.*" a != null then
            [ keys.${a} ] # "<user>@<host>" — one identity
        else
            map (n: keys.${n}) (filter (n: match "${a}@.*" n != null) (attrNames keys)); # "<user>" — all machines

    # ── Declared secrets: "location/name" (no `.age`). Recipients are computed; this list is the
    #    only thing you touch to add a secret. ─────────────────────────────────────────────────────
    declared = [
        # "cogs@glorpbook/gpg"        # example: this Mac's signing subkey (backup)
        # "cogs@home-desktop/gpg"   # the NixOS box's signing subkey (imported at activation)
        # "cogs/vpn"                # a profile for every cogs machine
    ];
in
listToAttrs (
    map (s: {
        name = "${s}.age";
        value.publicKeys = recipientsFor (audience s);
    }) declared
)
