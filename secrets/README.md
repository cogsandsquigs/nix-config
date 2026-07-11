# secrets

Encrypted with [agenix](https://github.com/ryantm/agenix). The `*.age` blobs are safe to commit —
only the matching **private** age key (`/etc/nix/age/<owner>`, gitignored) can decrypt them.

- **`recipients.nix`** — public keys per scope (`users/<name>`, `hosts/<name>`). Committed.
- **`secrets.nix`** — auto-computed rules; each `*.age` is encrypted to the key of its owning scope
  (first two path components). Never edit by hand.
- **`<scope>/<name>.age`** — a secret. Its _name_ is the path minus `.age` (e.g. `users/cogs/gpg`).

> Run every `agenix` command from **this dir** (`/etc/nix/secrets`) — that's where the rules live.

## 1 · Bootstrap an owner — once per user/host, on that machine

```sh
age-keygen -o /etc/nix/age/<owner>    # writes the PRIVATE key (keep secret), prints: Public key: age1…
age-keygen -y /etc/nix/age/<owner>    # reprint the public key anytime
```

Paste the `age1…` into `recipients.nix` under its scope, then commit `recipients.nix`.

## 2 · Add a secret

```sh
cd /etc/nix/secrets
agenix -e users/<owner>/<name>.age    # opens $EDITOR on the decrypted content: type, save, quit
git add users/<owner>/<name>.age      # commit the encrypted blob
```

Feed it to a feature in the owner's unit (`users/<owner>/home.nix`):

```nix
{ config, tools, ... }:               # add config + tools to the args
{
  age.secrets = tools.userSecret "<owner>" "<name>";
  my.user.<feature>.<pathOpt> = config.age.secrets."users/<owner>/<name>".path;
}
```

Then `rebuild`. _System_-scope instead? Use
`tools.sysSecret "<host>" "<name>" { owner = "<user>"; }` in the host file; its decrypted path lands
in `/run/agenix`.

## 3 · Edit / re-key

```sh
cd /etc/nix/secrets
agenix -e users/<owner>/<name>.age    # edit an existing secret
agenix -r                             # re-encrypt ALL secrets to current recipients (after key changes)
```

---

## Worked example — the GPG signing key (cogs)

⚠️ **Never move, replace, or delete your real key. You export a _copy_ only.**

```sh
# 0 · Safety backup of your whole GnuPG home first:
cp -a ~/.gnupg ~/.gnupg.bak.$(date +%Y%m%d)

# 1 · Find the signing key id (the `sec` line, e.g. rsa4096/E0DB58169CA551AA):
gpg --list-secret-keys --keyid-format=long

# 2 · Export a COPY of the secret key straight into a new agenix secret:
cd /etc/nix/secrets
gpg --export-secret-keys --armor <KEYID> > /tmp/gpg-cogs.asc
EDITOR="cp /tmp/gpg-cogs.asc" agenix -e users/cogs/gpg.age   # injects the file as the secret content
rm -P /tmp/gpg-cogs.asc                                      # secure-delete the temp copy (Linux: shred -u)

# 3 · Commit the encrypted blob:
git add users/cogs/gpg.age
```

Wire it in `users/cogs/home.nix` — this imports the key into the keyring at activation on any
machine that receives the secret (idempotent; a no-op where the key already exists):

```nix
{ config, tools, ... }:               # add config + tools to the args
{
  # …existing config…
  age.secrets = tools.userSecret "cogs" "gpg";
  my.user.git.signingKeyFile = config.age.secrets."users/cogs/gpg".path;
}
```

`rebuild`. The existing `signingKey` _id_ is unchanged; `signingKeyFile` only ensures the key is
present in the keyring elsewhere.

## OVPN — scaffolding ready, not created

Nothing to build: the helpers + rules already cover it. When you want it, follow **§2** — e.g. a
user secret `users/cogs/ovpn.age` (portable to any machine, no system layer needed), consumed
through a `tools.mkSecretPath` hole on the VPN feature. A system-scope variant via `tools.sysSecret`
is equally ready if you'd rather tie it to a NixOS host.
