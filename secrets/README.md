# secrets

Anything sensitive — a private key, a VPN profile, a token — gets encrypted here with
[agenix](https://github.com/ryantm/agenix) so it can live in the repo safely. The encrypted `*.age`
files are fine to commit and push; the only thing that decrypts them is your private age key at
`/etc/nix/age/<you>`, which is generated **per machine** and never leaves it (gitignored).

Three things live in this folder:

- **`recipients.nix`** — public age keys, one per **identity** = you on a specific machine, like
  `cogs@macbook`. The "who's allowed to read what" list.
- **`secrets.nix`** — worked out from the folder layout automatically; you never touch it.
- **the `*.age` files** — each under an **audience folder**: an identity (`cogs@home-desktop/…` →
  that machine only) or a bare user (`cogs/…` → all of your machines).

A secret is addressed by its folder + leaf: `cogs@home-desktop/gpg` is the file
`cogs@home-desktop/gpg.age`.

> Run `agenix` from inside this folder (`/etc/nix/secrets`), so it finds the rules.

## Stash a new secret

```sh
cd /etc/nix/secrets
agenix -e cogs/api-token.age    # a "cogs" (all-your-machines) secret — opens your editor; type it in, save
git add cogs/api-token.age      # the encrypted file is safe to commit
```

Use it from your config (`users/cogs/home.nix`):

```nix
{ config, tools, ... }:
{
  age.secrets              = tools.secrets.declare "cogs" "api-token";
  my.user.<feature>.<hole> = tools.secrets.path config "cogs" "api-token";
}
```

`rebuild`. `declare` registers it so agenix decrypts it at activation; `path` is where the plaintext
lands at runtime, which you hand to the feature.

## Change one later

```sh
cd /etc/nix/secrets
agenix -e cogs/api-token.age    # re-opens it decrypted; edit and save
```

Added or replaced a key in `recipients.nix`? Re-encrypt everything to match: `agenix -r`.

## New machine (or new person)

Every machine gets its own key. On that machine:

```sh
age-keygen -o /etc/nix/age/cogs   # makes the private key (keep it!), prints a "Public key: age1…"
```

Add that `age1…` to `recipients.nix` as `"cogs@<host>"` and commit. Then re-key any all-machines
secrets so the new box can read them: `agenix -r`.

## Keep your GPG signing key across machines

You use an offline master key with a per-machine signing subkey (the secure setup). A new machine
needs its own subkey — stash it here, encrypted to just that machine, and it imports on activation.

> ⚠️ Export the **subkey only**, never the master secret. Back up `~/.gnupg` first anyway.

```sh
cp -a ~/.gnupg ~/.gnupg.backup

gpg --list-secret-keys --keyid-format=long        # note your PRIMARY fingerprint + the signing subkey id

cd /etc/nix/secrets
gpg --export-secret-subkeys --armor <SUBKEY>! > /tmp/sub.asc   # the trailing ! pins that one subkey
EDITOR="cp /tmp/sub.asc" agenix -e cogs@home-desktop/gpg.age   # drop it into the secret for that machine
rm -P /tmp/sub.asc                                             # wipe the temp copy (Linux: shred -u)

git add cogs@home-desktop/gpg.age
```

Wire it per-machine in `users/cogs/home.nix`, gated so only boxes provisioned this way import it (the
machine you made the key on already has it in its keyring):

```nix
{ config, lib, tools, hostId, ... }:
let
  me = "cogs@${hostId.hostName}";
  syncGpg = builtins.elem hostId.hostName [ "home-desktop" ];   # boxes that import via agenix
in
{
  age.secrets                = lib.mkIf syncGpg (tools.secrets.declare me "gpg");
  my.user.git.signingKeyFile = lib.mkIf syncGpg (tools.secrets.path config me "gpg");
}
```

`rebuild`. Set git `signingKey` to your **primary key fingerprint** (constant on every machine) so
each box automatically uses whichever signing subkey it has locally.

## OpenVPN

Same as any secret: `agenix -e cogs/ovpn.age` with your profile (a `cogs` all-machines secret), then
point the VPN feature at `tools.secrets.path config "cogs" "ovpn"`.
