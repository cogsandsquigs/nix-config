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
    listToAttrs
    ;

  # First path segment = the audience folder.
  #
  # i.e., each sub-folder in this dir specifies either a user or a host or both. The audience is
  # that exact specification, either `<user>`, `<host>`, or `<user>@<host>` (both).
  audience = f: elemAt (filter isString (split "/" f)) 0;

  recipientsFor =
    audience:
    # If this matches, then `audience` is of a format `<user>@<host>` -- only that specific key
    # is used for this secret.
    if match ".*@.*" audience != null then
      [ keys.${audience} ] # "<user>@<host>" — one identity

    # Otherwise, we assume the shape is `<user>`. Then we just get all keys in `recipients.nix`
    # of the form `<user>@*`, and those are the keys that are applicable.
    #
    # WARN: When we have host-specific secrets, this will need to be extended to match the
    # audience string against `".*@${host}"`.
    else
      map (identity: keys.${identity}) (filter (n: match "${audience}@.*" n != null) (attrNames keys));

  # ── Declared secrets: "location/name" (no `.age`). Recipients are computed; this list is the
  #    only thing you touch to add a secret. ─────────────────────────────────────────────────────
  declared = [
    "cogs@glorpbook/gpg" # this Mac's signing subkey (backup + pipeline test)
    # "cogs@home-desktop/gpg"   # the NixOS box's signing subkey (imported at activation)
    "cogs/work-alt-ipratt-ovpn" # work OpenVPN profile (all cogs machines)
  ];
in
listToAttrs (
  map (s: {
    name = "${s}.age";
    value.publicKeys = recipientsFor (audience s);
  }) declared
)
