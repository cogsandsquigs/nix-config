# secrets

Anything sensitive — a private key, a VPN profile, a token — gets encrypted here with
[agenix](https://github.com/ryantm/agenix) so it can live in the repo safely. The encrypted `*.age`
files are fine to commit and push; the only thing that can decrypt them is your private age key at
`/etc/nix/age/<you>`, which never leaves the machine (it's gitignored).

Three things live in this folder:

- **`recipients.nix`** — the public age keys, one per person/machine. This is the "who's allowed to
  read what" list.
- **`secrets.nix`** — worked out automatically from the folder layout; you never touch it.
- **the `*.age` files** — the secrets themselves, filed under `users/<you>/…` or `hosts/<box>/…`.

A secret's _name_ is just its path here without the `.age` — so `users/cogs/gpg.age` is called
`users/cogs/gpg`.

> Run `agenix` from inside this folder (`/etc/nix/secrets`), so it finds the rules.

## Stash a new secret

```sh
cd /etc/nix/secrets
agenix -e users/cogs/api-token.age    # opens your editor on the (empty) secret — type it in, save, quit
git add users/cogs/api-token.age      # the encrypted file is safe to commit
```

That's it — it's stored. To actually _use_ it, hand its decrypted path to a feature from your own
config (`users/cogs/home.nix`):

```nix
{ config, tools, ... }:               # make sure config + tools are in the args
{
  age.secrets = tools.userSecret "cogs" "api-token";
  my.user.<feature>.<somePath> = config.age.secrets."users/cogs/api-token".path;
}
```

`rebuild`, and the feature reads it from a decrypted file that only exists at runtime. (If it's a
whole-machine thing rather than yours specifically, use
`tools.sysSecret "<box>" "<name>" { owner = "cogs"; }` in the host file instead — it shows up under
`/run/agenix`.)

## Change one later

```sh
cd /etc/nix/secrets
agenix -e users/cogs/api-token.age    # re-opens it decrypted; edit and save
```

If you ever add or replace a key in `recipients.nix`, re-encrypt everything to match with
`agenix -r`.

## New machine or new person

Each person/machine needs its own key before it can read anything. On that machine:

```sh
age-keygen -o /etc/nix/age/cogs       # makes the private key (keep it!), prints a "Public key: age1…"
```

Copy that `age1…` line into `recipients.nix` under the right name (`users/cogs`, `hosts/desk`, …)
and commit it. Lost track of the public key later? `age-keygen -y /etc/nix/age/cogs` prints it
again.

## Keep your GPG signing key across machines

Right now your commit-signing key only exists on the machine you made it on. Stash a copy here and
every machine picks it up automatically.

> You're only exporting a **copy**. Your real key is never touched — but back it up first anyway.

```sh
cp -a ~/.gnupg ~/.gnupg.backup             # just in case

gpg --list-secret-keys --keyid-format=long # find the key id (the `sec` line, e.g. …/E0DB58169CA551AA)

cd /etc/nix/secrets
gpg --export-secret-keys --armor <KEYID> > /tmp/key.asc
EDITOR="cp /tmp/key.asc" agenix -e users/cogs/gpg.age   # drops the exported key into the secret
rm -P /tmp/key.asc                                      # wipe the temp copy (on Linux: shred -u)

git add users/cogs/gpg.age
```

Then tell git about it in `users/cogs/home.nix`:

```nix
{ config, tools, ... }:               # add config + tools to the args
{
  # …the rest of your config…
  age.secrets = tools.userSecret "cogs" "gpg";
  my.user.git.signingKeyFile = config.age.secrets."users/cogs/gpg".path;
}
```

`rebuild`. From now on any machine that gets this config imports the key into its keyring on
activation (it's a harmless no-op on the machine that already has it). Your `signingKey` id doesn't
change — this just makes sure the key is actually _there_ to sign with.

## OpenVPN

Not set up yet, but it works exactly like anything else above: `agenix -e users/cogs/ovpn.age` with
your profile, then point the VPN feature at its path. Do it as a user secret and it follows you to
any machine; use `tools.sysSecret` instead if you'd rather pin it to one box.
