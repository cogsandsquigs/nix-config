let
    # A secret is addressed by (location, name): `location` is its audience folder under `secrets/` -- an
    # identity "<user>@<host>" for one machine, or a bare "<user>" for that user everywhere (see
    # secrets/.sops.yaml for how a folder resolves to recipients). `../secrets` resolves relative to THIS
    # file, so it is the repo-root `secrets/` regardless of caller.
    secretFile = location: name: ../secrets + "/${location}/${name}.sops";

    # The `sops.secrets` identifier, and so the decrypted runtime filename. FLATTENED (`/` -> `-`) so
    # "cogs@glorpbook" + "gpg" is one key, not a nested attr. Only this key is flat; the `.sops` path
    # above stays nested.
    keyOf = location: name: builtins.replaceStrings [ "/" ] [ "-" ] "${location}/${name}";

in
{
    # -- tools.secrets -- sops wiring (register + consume) -----------------------------------------
    # A feature stays secret-AGNOSTIC: it exposes an `opt.mkSecretPath` hole and nothing more. The
    # user/host unit does both sops steps -- `declare` registers the secret so sops decrypts it at
    # activation, `path` reads back where the plaintext landed and feeds the feature's hole.
    #
    #   sops.secrets = tools.secrets.declare "cogs@glorpbook" "gpg";
    #
    # `format = "binary"` means the decrypted payload is the raw file bytes (an exported GPG key, a
    # certificate), not a value looked up inside a YAML document.
    declare = location: name: {
        "${keyOf location name}" = {
            sopsFile = secretFile location name;
            format = "binary";
        };
    };
    # read the decrypted runtime path:  tools.secrets.path config "cogs@glorpbook" "gpg"
    path =
        config: location: name:
        config.sops.secrets.${keyOf location name}.path;
}
