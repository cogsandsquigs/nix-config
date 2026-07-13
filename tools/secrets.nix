let
    # A secret is addressed by (location, name): `location` is its audience folder under `secrets/`
    # (an identity "<user>@<host>", or a bare "<user>" for that user on all machines); `name` is the
    # leaf. The encrypted file is `secrets/<location>/<name>.age`. `../secrets` resolves relative to
    # THIS file (lib/) — the repo-root `secrets/` — regardless of caller.
    secretFile = location: name: ../secrets + "/${location}/${name}.age";

    # The `age.secrets` identifier (and the decrypted runtime filename). FLATTENED — `/` → `-` — so a
    # nested location like "cogs@glorpbook" doesn't make agenix write into a subdir of its per-user
    # secretsDir that it never creates (the file just wouldn't appear). The `.age` file path above
    # stays nested; only this runtime key is flat.
    keyOf = location: name: builtins.replaceStrings [ "/" ] [ "-" ] "${location}/${name}";

    # Build an `age.secrets` fragment. In `let` so the `secrets.*` set below can reuse it.
    mkSecret = location: name: attrs: {
        "${keyOf location name}" = {
            file = secretFile location name;
        }
        // attrs;
    };
in
{

    # ── tools.secrets — agenix wiring (register + consume) ───────────────────────────────────────
    # A feature stays secret-AGNOSTIC: it only exposes an `opt.mkSecretPath` hole. The user/host unit
    # does the two agenix steps: `declare` registers the secret (so agenix decrypts it at activation),
    # `path` reads back where the plaintext lands — which it feeds into the feature's hole. Scope is
    # carried by `location`, not by a function name: an identity "<user>@<host>" is that machine only;
    # a bare "<user>" is that user on all their machines (see secrets/secrets.nix for how each folder
    # resolves to recipients).
    # register with agenix:  age.secrets = tools.secrets.declare "cogs@glorpbook" "gpg";
    declare = location: name: mkSecret location name { };
    # same, with extra agenix attrs (owner/mode) for system secrets in /run/agenix
    inherit mkSecret;
    # read the decrypted runtime path:  tools.secrets.path config "cogs@glorpbook" "gpg"
    path =
        config: location: name:
        config.age.secrets.${keyOf location name}.path;
}
