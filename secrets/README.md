# secrets

Anything sensitive — a private key, a VPN profile, a token — gets encrypted here with
[sops](https://github.com/getsops/sops) (using [sops-nix](https://github.com/Mic92/sops-nix) to
decrypt it at activation) so it can live in the repo safely. The encrypted `*.sops` files are fine to
commit and push; the only thing that decrypts them is your private age key at `/etc/nix/age/<you>`,
which is generated **per machine** and never leaves it (gitignored).

Two things live in this folder:

- **`.sops.yaml`** — the `creation_rules`: a list of `path_regex → age public key(s)`. This is the
  "who's allowed to read what" list. The `sops` CLI reads it when you create/edit/re-key a secret.
- **the `*.sops` files** — each under an **audience folder**: an identity (`cogs@home-desktop/…` →
  that machine only) or a bare user (`cogs/…` → all of your machines). Which key a secret is
  encrypted to is decided by the first `path_regex` in `.sops.yaml` that matches its folder.

A secret is addressed by its folder + leaf: `cogs@home-desktop/gpg` is the file
`cogs@home-desktop/gpg.sops`.

> Running the CLI:
>
> - Your identity is an age key at `/etc/nix/age/<you>` (not in `~/.ssh`), so **decrypt / edit /
>   re-key need it**: `export SOPS_AGE_KEY_FILE=/etc/nix/age/<you>` first (or pass it inline).
> - **Creating** a brand-new secret doesn't need your key (it only encrypts, to the recipient from
>   `.sops.yaml`).

## Stash a new secret

If the folder is new, first add a `creation_rule` for it in `.sops.yaml` (which key can read it).
Then encrypt a plaintext file into place with the helper:

```sh
./sops-stash.sh ~/api-token.txt cogs/api-token   # → secrets/cogs/api-token.sops
```

(`sops-stash.sh` is just a wrapper around `sops encrypt --input-type binary`; the recipient is picked
from `.sops.yaml` by the `cogs/api-token` path.)

Use it from your config (`users/cogs/home.nix`):

```nix
{ config, tools, ... }:
{
  sops.secrets             = tools.secrets.declare "cogs" "api-token";
  my.user.<feature>.<hole> = tools.secrets.path config "cogs" "api-token";
}
```

`rebuild`. `declare` registers it so sops decrypts it at activation; `path` is where the plaintext
lands at runtime (`~/.config/sops-nix/secrets/<flattened-name>`), which you hand to the feature.

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
age-keygen -o /etc/nix/age/cogs   # makes the private key (keep it!), prints a "Public key: age1…"
```

Add that `age1…` to the relevant `creation_rules` in `.sops.yaml` (e.g. the `cogs/` rule so the new
box can read all-machines secrets) and commit. Then re-key those secrets so the new key is included:
`sops updatekeys <file>.sops` (needs `SOPS_AGE_KEY_FILE` set to an existing identity).

## Keep your GPG signing key across machines

You use an offline master key with a per-machine signing subkey (the secure setup). A new machine
needs its own subkey — stash it here, encrypted to just that machine, and it imports on activation.

> ⚠️ Export the **subkey only**, never the master secret. Back up `~/.gnupg` first anyway.

Add a `creation_rule` matching `cogs@home-desktop/` in `.sops.yaml` first (encrypted to that machine's
key). Then:

```sh
cp -a ~/.gnupg ~/.gnupg.backup

gpg --list-secret-keys --keyid-format=long        # note your PRIMARY fingerprint + the signing subkey id

gpg --export-secret-subkeys --armor <SUBKEY>! > /tmp/sub.asc   # the trailing ! pins that one subkey
./sops-stash.sh /tmp/sub.asc cogs@home-desktop/gpg             # → secrets/cogs@home-desktop/gpg.sops
rm -P /tmp/sub.asc                                             # wipe the temp copy (Linux: shred -u)
```

Wire it per-machine in `users/cogs/home.nix` — gated on whether the `.sops` file exists (so only
provisioned machines import; the machine where the key was created already has it in its keyring):

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

The steps above copy your existing subkeys to a new box. If you'd rather each machine have its
**own** signing (+ encryption) subkey — so you can revoke one box without touching the others — use
[`./mint-subkeys.sh`](./mint-subkeys.sh). It mints them from your master and stashes them as the
machine's secret in one go.

> ⚠️ It needs the master **secret**, so run it on your **air-gapped** box (where the master lives),
> not a daily machine. See the header comment for the full flow and caveats.

```sh
./mint-subkeys.sh <master-secret.asc> <host>   # → secrets/cogs@<host>/gpg.sops
```

## OpenVPN

Same as any secret: `./sops-stash.sh ~/profile.ovpn cogs/ovpn` (a `cogs` all-machines secret), then
point the VPN feature at `tools.secrets.path config "cogs" "ovpn"`.
