let
    # A secret is addressed by (location, name): `location` is its audience folder under `secrets/`
    # (an identity "<user>@<host>", or a bare "<user>" for that user on all machines); `name` is the
    # leaf. The encrypted file is `secrets/<location>/<name>.sops`. `../secrets` resolves relative to
    # THIS file (tools/) — the repo-root `secrets/` — regardless of caller.
    secretFile = location: name: ../secrets + "/${location}/${name}.sops";

    # The `sops.secrets` identifier (and the decrypted runtime filename). FLATTENED — `/` → `-` — so a
    # nested location like "cogs@glorpbook" becomes a single flat key ("cogs@glorpbook-gpg") rather
    # than a nested attr. The `.sops` file path above stays nested; only this runtime key is flat.
    keyOf = location: name: builtins.replaceStrings [ "/" ] [ "-" ] "${location}/${name}";

    # Build a `sops.secrets` fragment. `format = "binary"` means "the decrypted payload is the raw
    # file bytes" (an .ovpn, an exported GPG key) — not a value looked up inside a YAML/JSON document.
    # In `let` so `declare` below can reuse it.
    mkSecret = location: name: attrs: {
        "${keyOf location name}" = {
            sopsFile = secretFile location name;
            format = "binary";
        }
        // attrs;
    };
in
{

    # ── tools.secrets — sops wiring (register + consume) ─────────────────────────────────────────
    # A feature stays secret-AGNOSTIC: it only exposes an `opt.mkSecretPath` hole. The user/host unit
    # does the two sops steps: `declare` registers the secret (so sops decrypts it at activation),
    # `path` reads back where the plaintext lands — which it feeds into the feature's hole. Scope is
    # carried by `location`, not by a function name: an identity "<user>@<host>" is that machine only;
    # a bare "<user>" is that user on all their machines (see secrets/.sops.yaml for how each folder
    # resolves to recipients).
    # register with sops:  sops.secrets = tools.secrets.declare "cogs@glorpbook" "gpg";
    declare = location: name: mkSecret location name { };
    # same, with extra sops attrs (owner/mode) when a secret needs them
    inherit mkSecret;
    # read the decrypted runtime path:  tools.secrets.path config "cogs@glorpbook" "gpg"
    path =
        config: location: name:
        config.sops.secrets.${keyOf location name}.path;
}
