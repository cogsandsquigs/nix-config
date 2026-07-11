# agenix rules — who each secret is encrypted to. Add "location/name" to `declared`; recipients
# are auto-computed: contains "@" → exact identity ("<user>@<host>"); no "@" → all "<user>@*" keys.
# Pure builtins only — agenix evaluates this without a guaranteed NIX_PATH.
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
        "cogs@glorpbook/gpg" # this Mac's signing subkey (backup + pipeline test)
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
