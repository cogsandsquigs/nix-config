# secrets

Anything sensitive -- a private key, a VPN profile, a token -- is encrypted here with
[sops](https://github.com/getsops/sops), so it can live in the repo safely.
[sops-nix](https://github.com/Mic92/sops-nix) decrypts it at activation. The encrypted `*.sops`
files are safe to commit and push. Only your private age key decrypts them. That key lives at
`/etc/nix/age/<you>`, is generated **per machine**, and never leaves it (gitignored).

Two things live in this folder:

- **`.sops.yaml`** -- the `creation_rules`, a list of `path_regex -> age public key(s)`. This is the
  "who may read what" list. The `sops` CLI reads it when you create, edit, or re-key a secret.
- **the `*.sops` files** -- each under an **audience folder**, either an identity
  (`cogs@glorpbox/...` reaches that machine only) or a bare user (`cogs/...` reaches all of your
  machines). The first `path_regex` in `.sops.yaml` that matches the folder picks the key.

A secret is addressed by its folder + leaf: `cogs@glorpbox/gpg` is the file
`cogs@glorpbox/gpg.sops`.

> Running the CLI:
>
> - Your identity is an age key at `/etc/nix/age/<you>`, not in `~/.ssh`. **Decrypt, edit, and
>   re-key need it.** Run `export SOPS_AGE_KEY_FILE=/etc/nix/age/<you>` first, or pass it inline.
> - **Creating** a new secret does not need your key. It only encrypts, to the recipient that
>   `.sops.yaml` names.

## Stash a new secret

If the folder is new, first add a `creation_rule` for it in `.sops.yaml` (which key can read it).
Then encrypt a plaintext file into place with the helper:

```sh
./sops-stash.sh ~/api-token.txt cogs/api-token   # -> secrets/cogs/api-token.sops
```

(`sops-stash.sh` only wraps `sops encrypt --input-type binary`. The `cogs/api-token` path picks the
recipient from `.sops.yaml`.)

Use it from your config (`users/cogs/home.nix`):

```nix
{ config, tools, ... }:
{
  sops.secrets             = tools.secrets.declare "cogs" "api-token";
  my.user.<feature>.<hole> = tools.secrets.path config "cogs" "api-token";
}
```

`rebuild`. `declare` registers the secret, so sops decrypts it at activation. `path` is where the
plaintext lands at runtime (`~/.config/sops-nix/secrets/<flattened-name>`). Hand that path to the
feature.

## Change one later

Replace the contents by re-stashing the new plaintext:

```sh
./sops-stash.sh ~/api-token.new cogs/api-token
```

Added or replaced a key in `.sops.yaml`? Re-encrypt the affected secrets to match:

```sh
export SOPS_AGE_KEY_FILE=/etc/nix/age/cogs
sops updatekeys cogs/api-token.sops
```

## New machine (or new person)

Every machine gets its own key. On that machine:

```sh
age-keygen -o /etc/nix/age/cogs   # makes the private key (keep it!), prints a "Public key: age1..."
```

Add that `age1...` to the relevant `creation_rules` in `.sops.yaml` (e.g. the `cogs/` rule so the
new box can read all-machines secrets) and commit. Then re-key those secrets so the new key is
included: `sops updatekeys <file>.sops` (needs `SOPS_AGE_KEY_FILE` set to an existing identity).

## Keep your GPG signing key across machines

You use an offline master key with a per-machine signing subkey, which is the secure setup. A new
machine needs its own subkey. Stash it here, encrypted to that machine alone, and it imports on
activation.

> WARNING: Export the **subkey only**, never the master secret. Back up `~/.gnupg` first anyway.

Add a `creation_rule` matching `cogs@glorpbox/` in `.sops.yaml` first (encrypted to that machine's
key). Then:

```sh
cp -a ~/.gnupg ~/.gnupg.backup

gpg --list-secret-keys --keyid-format=long        # note your PRIMARY fingerprint + the signing subkey id

gpg --export-secret-subkeys --armor <SUBKEY>! > /tmp/sub.asc   # the trailing ! pins that one subkey
./sops-stash.sh /tmp/sub.asc cogs@glorpbox/gpg             # -> secrets/cogs@glorpbox/gpg.sops
rm -P /tmp/sub.asc                                             # wipe the temp copy (Linux: shred -u)
```

Wire it per machine in `users/cogs/home.nix`, gated on whether the `.sops` file exists. Only
provisioned machines then import it. The machine where you created the key already holds it in its
keyring.

```nix
{ config, lib, tools, hostId, ... }:
let
  me = "cogs@${hostId.hostName}";
  haveGpg = builtins.pathExists (../../secrets + "/${me}/gpg.sops");
in
{
  sops.secrets               = lib.mkIf haveGpg (tools.secrets.declare me "gpg");
  my.user.git.signingKeyFile = lib.mkIf haveGpg (tools.secrets.path config me "gpg");
}
```

`rebuild`. Set git `signingKey` to your **primary key fingerprint** (constant on every machine) so
each box automatically uses whichever signing subkey it has locally.

### Minting a _fresh_ subkey per machine (stronger isolation)

The steps above copy your existing subkeys to a new box. To give each machine its **own** signing
and encryption subkey, so you can revoke one box without touching the others, use
[`./mint-subkeys.sh`](./mint-subkeys.sh). It mints them from your master and stashes them as the
machine's secret in one step.

> WARNING: It needs the master **secret**, so run it on your **air-gapped** box (where the master
> lives), not a daily machine. See the header comment for the full flow and caveats.

```sh
./mint-subkeys.sh <master-secret.asc> <host>   # -> secrets/cogs@<host>/gpg.sops
```

## OpenVPN

Same as any secret: `./sops-stash.sh ~/profile.ovpn cogs/ovpn` (a `cogs` all-machines secret), then
point the VPN feature at `tools.secrets.path config "cogs" "ovpn"`.
