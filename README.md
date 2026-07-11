# nix

My personal NixOS / nix-darwin / home-manager configuration! A single-user, single-repo flake that
builds a Mac, a personal Linux desktop, and a standalone-home-manager work desktop.

## Overview

This is a **plain flake**. Every file under `modules/` is an ordinary NixOS / nix-darwin /
home-manager module, and **the directory tree _is_ the import graph**: each `default.nix` imports
its siblings and children, so you can read a folder top-down to see exactly what it pulls in.

Three hosts are built:

| Host                 | Class        | Platform         | Attribute                                   | User(s)            |
| -------------------- | ------------ | ---------------- | ------------------------------------------- | ------------------ |
| `glorpbook` | nix-darwin   | `aarch64-darwin` | `darwinConfigurations."glorpbook"` | `cogs` (personal)  |
| `home-desktop`       | NixOS        | `x86_64-linux`   | `nixosConfigurations.home-desktop`          | `cogs` (personal)  |
| `work-desktop`       | home-manager | `x86_64-linux`   | `homeConfigurations."ipratt@work-desktop"`  | `ipratt` (work)    |

The first two are **system** configs (nix-darwin / NixOS) applied with `*-rebuild`. The third is a
**standalone home-manager** config for a work machine (Ubuntu 24) where Nix is installed per-user —
there is no system layer, and it's applied with `home-manager switch`.

**Two layers of selection.** A host picks _which users_ live on it; a user picks _which home
features_ it wants. Neither touches feature-module code — that's the whole design (see
[the `users/` layer](#the-users-layer) and [feature toggles](#feature-toggles)):

- **`hosts/<host>/`** — pure host selection: platform, host-only tweaks, the list of user units
  placed on the machine (`id.nix`'s `users`), and which _system_ features it opts into
  (`my.sys.<feature>.enable`).
- **`users/<user>/`** — an **isolated, portable unit**: one human's identity, home feature set
  (`my.user.<feature>.enable`), and (on full-OS hosts) system account. The same user can be dropped
  onto any host by name. `cogs` turns on the personal extras (games + GUI apps); `ipratt` leaves them
  off for a lean work profile, with a work git identity.

Every user imports the **same full home library** (`modules/home`); the difference between `cogs`
and `ipratt` is purely which `my.user.*` flags each flips. There is no import-bundle split — see
[feature toggles](#feature-toggles).

Key inputs (see `flake.nix`): [nixpkgs] (stable), [nix-darwin], [home-manager],
[Determinate Nix][determinate], and [agenix] for secrets.

## Structure

- **`flake.nix`** — Inputs + outputs. Declares the three host configurations and the formatter.
- **`flake.lock`** — Pinned input revisions.
- **`lib/default.nix`** — The _only_ place that knows how a host is assembled:
  - `mkDarwin` / `mkNixos` — build a **system** host from `./hosts/<name>` +
    `modules/system/<class>`.
  - `mkHome` — build a **standalone home-manager** host from `./hosts/<name>` + the host's single
    user unit (`users/<user>/home.nix`). Owns its own `pkgs` (allowUnfree/qt) since there's no
    system layer.
  - `forAllSystems` — map over systems for per-system outputs (e.g. the formatter).
  - `specialArgsFor` — the `specialArgs`/`extraSpecialArgs` every builder shares: `inputs`,
    `hostId`, and `tools` (the option-constructor helpers, below).
- **`lib/opts.nix`** — our small helper library, passed to every module as the `tools` argument
  (system and home alike). Option constructors (`mkEnabled`, `mkDisabled`, `mkRiding`, `mkStr`,
  `mkEnum`, …) + safety helpers (`requires`) used by the [feature-toggle](#feature-toggles) modules.
  It's a dedicated arg rather than folded into `lib` on purpose — extending the home `lib` clobbers
  home-manager's own `lib.hm.*` (see the note in the file).
- **`hosts/`** — Per-machine **selection**. Each host has an **`id.nix`**
  (`{ hostName; system; users; primaryUser; }` — host identity + which user units live here; see the
  [`id.nix` / `hostId` convention](#the-idnix--hostid-convention)) plus a `default.nix` for host-only
  tweaks. No user identity or feature logic lives here.
  - **`glorpbook/`** — darwin host (dock, TouchID sudo, homebrew, launchd).
  - **`home-desktop/`** — personal NixOS host.
  - **`work-desktop/`** — standalone home-manager host (Ubuntu). Nothing host-specific beyond its
    `id.nix`; identity, git, and `my.user.flakeDir` all live in the `ipratt` user unit.
- **`users/`** — Per-user **isolated, portable units** (see [the `users/` layer](#the-users-layer)).
  Each `users/<name>/` has `identity.nix` (plain data), `home.nix` (home-manager feature set + git
  identity), and `system.nix` (system account, used only on full-OS hosts).
  - **`cogs/`** — the personal user (full profile).
  - **`ipratt/`** — the work user (lean core profile, work git identity, signing off).
- **`modules/`**
  - **`home-manager.nix`** — Wires each user the host declares (`hostId.users`) to its
    `users/<name>/home.nix`; used by the two system classes.
  - **`system/`** — System-level config (only the system hosts use this).
    - **`common/`** — Valid on BOTH classes (nixpkgs settings, shells).
    - **`darwin/`** — macOS-only (`default.nix` imports `common` + everything here).
    - **`nixos/`** — Linux-only.
  - **`home/`** — home-manager config, class-agnostic. OS differences handled inline
    (`lib.optionals pkgs.stdenv.isDarwin ...`). `default.nix` imports the **full feature library**;
    every module owns its own `my.user.<feature>.enable` flag ([feature toggles](#feature-toggles)),
    so nothing is a separate import-bundle.
    - **`base.nix`** — plumbing (stateVersion, home dir); no flag.
    - **`git.nix`, `ssh.nix`, `terminal.nix`** — core features (on by default). `git.nix` also holds
      the identity/signing value options (`my.user.git.userName/email/signingKey/…`) — the only
      per-user-varying bits.
    - **`shell/`** — Shell + prompt (core). Holds `my.user.flakeDir` (per-host repo path).
    - **`utils/`** — gpg, yazi, zellij, … (core group).
    - **`dev/`** — dev toolchain **group**: master `my.user.dev.enable` with ride-along sub-features
      (`ide`, `direnv`, `containers`, `langs/`, and editors — `helix` on, `vscode` opt-in install-only).
    - **`games.nix`, `desktop-apps/`** — optional features (off by default); `cogs` opts in.
- **`scripts/`** — Convenience wrappers: `rebuild.sh`, `upgrade.sh`, `cleanup.sh`, `editnix.sh`.
  Location-independent (they derive the flake dir from their own path) and auto-detect whether to
  use `darwin-rebuild` / `nixos-rebuild` / standalone `home-manager switch`.
- **`secrets/`** — agenix-encrypted secrets + their rules (`recipients.nix`, computed `secrets.nix`),
  plus `mint-subkeys.sh` and a how-to `README.md`. See [Secrets](#secrets).
- **`nix.conf`** — Nix daemon settings.
- **`treefmt.toml`** — one-command repo formatting (`treefmt`); also the home of nixfmt's
  `--width`/`--indent` options, since nixfmt has no native config file. Mirrors the per-language
  formatter settings in the helix config (4-space, 100 cols).
- **`.prettierrc.json`** — prettier options (4-space, 100 cols) for JSON/YAML/JS/CSS/…, picked up
  automatically by prettier / prettierd (editor and `treefmt` alike).

### How a host is assembled

For a **system** host, `flake.nix` calls e.g. `lib.mkDarwin ./hosts/glorpbook`, which produces a
system from two module lists:

1. `modules/system/<class>` — the shared system config for that OS. Its `default.nix` also imports
   `modules/system/common`, pulls in home-manager via `modules/home-manager.nix`, and declares
   system accounts via `system/<class>/users.nix`. Both of those iterate the host's `id.nix`
   `users` list: each user's `users/<name>/home.nix` becomes a `home-manager.users.<name>` entry,
   and each `users/<name>/system.nix` becomes a system account.
2. `./hosts/<name>` — the machine-specific bits.

For the **standalone home-manager** host, `flake.nix` calls
`lib.mkHome { host = ./hosts/work-desktop; }`. There is no system layer: `mkHome` reads the host's
single user from `id.nix` and builds a `homeConfigurations` entry directly from
`users/<user>/home.nix` + the host file (setting `home.username` to that user).

So **hosts pick users, users pick features.** A host never names a home feature; a user never names a
host. That two-layer split is what lets a user be moved to another machine (or a second user added to
a machine) by editing only `id.nix`.

### The `users/` layer

Each `users/<name>/` is an **isolated, portable unit** — everything about one human account, with no
reference to any hostname or other user, so it can be placed on any host by name (a host lists it in
`id.nix`'s `users`). Three files:

```
users/<name>/
  identity.nix   # plain-data attrset: { username = "cogs"; }. No module args — importable anywhere
                 # (flake output naming, standalone home.username) without the module system.
  home.nix       # home-manager module: imports the full home library (modules/home) and sets this
                 # user's my.user.* flags + values (which features are on, git identity, flakeDir).
  system.nix     # NixOS/darwin module: users.users.<name> account attrs. Imported only on full-OS
                 # hosts; class-portable (NixOS-only attrs guarded behind pkgs.stdenv.isLinux).
```

The feature set is a property of the **user**, not the host: both `users/cogs/home.nix` and
`users/ipratt/home.nix` import the same `modules/home`, and differ only in the `my.user.*` flags they
set — `cogs` turns on `games`/`desktopApps`, `ipratt` leaves them off (see
[feature toggles](#feature-toggles)). Putting the work user on a personal machine means adding
`"ipratt"` to that host's `users` — it arrives as a distinct account with its own feature selection,
not a "work profile" of `cogs`.

**To add a new user:** create `users/<name>/{identity.nix,home.nix,system.nix}` (copy an existing
unit), import `modules/home` in `home.nix`, flip the `my.user.*` flags you want and set
`my.user.git.*`, then add `"<name>"` to the `users` list of whichever host(s) should have it.

### The `id.nix` / `hostId` convention

Every host directory carries an **`id.nix`** — a plain attrset that is the single source of truth for
that machine's **host** identity (no user identity — that lives in `users/`):

```nix
# hosts/<name>/id.nix
{
    hostName    = "home-desktop";  # the machine's hostname
    system      = "x86_64-linux";  # the machine's platform (nixpkgs.hostPlatform)
    users       = [ "cogs" ];      # which user units live on this machine
    primaryUser = "cogs";          # the user owning host-level singletons (below)
}
```

It flows through the config in exactly two ways, so the name is never repeated:

1. **Into the modules as `hostId`.** The builders in `lib/default.nix` (`mkDarwin` / `mkNixos` /
   `mkHome`) `import` the host's `id.nix` and pass it via `specialArgs`/`extraSpecialArgs` as the
   `hostId` argument. Modules read it to drive per-host wiring without hardcoding names:
   - `modules/home-manager.nix` → one `home-manager.users.<name>` per `hostId.users`.
   - `modules/system/{darwin,nixos}/users.nix` → imports `users/<name>/system.nix` per `hostId.users`.
   - the host file itself → `networking.hostName = hostId.hostName`, `nixpkgs.hostPlatform =
     hostId.system`, and (glorpbook) `system.primaryUser` / homebrew owner from `hostId.primaryUser`.
2. **Into `flake.nix` for the output attribute names.** `flake.nix` reads each `id.nix` to form
   `darwinConfigurations.<hostName>`, `nixosConfigurations.<hostName>`, and
   `homeConfigurations."<primaryUser>@<hostName>"`. `scripts/rebuild.sh` then *discovers* the
   standalone name from the flake rather than hardcoding it.

**`primaryUser`** exists because some host-level singletons take exactly one user (nix-darwin's
`system.primaryUser`, the Homebrew prefix owner). On a single-user host it's just that user; on a
multi-user host it's whichever account owns those singletons.

**Naming:** fields are camelCase (`hostName`, `system`, `users`, `primaryUser`). Keep them in that
style.

**To add a new host:**

1. `mkdir hosts/<name>` and write `hosts/<name>/id.nix` (`{ hostName; system; users; primaryUser; }`),
   listing existing (or new — see [the `users/` layer](#the-users-layer)) user units in `users`.
2. Write `hosts/<name>/default.nix` — the machine-specific module. Pull host identity from the
   `hostId` argument (don't re-`import ./id.nix`); no user or feature logic belongs here.
3. Wire it up in `flake.nix`: read its id (`idOf ./hosts/<name>`) and add the matching
   `darwinConfigurations` / `nixosConfigurations` / `homeConfigurations` entry via the right
   `lib.mk*` builder.

## Feature toggles

Every feature is an independent module that **owns its own `enable` flag**. Turning a feature on or
off for a host or a user is one line in one file — you never touch the feature's module. This is the
core design goal.

**Two scopes:**

- **`my.sys.<feature>.enable`** — a **system** feature (per host). Set it in `hosts/<host>/default.nix`.
- **`my.user.<feature>.enable`** — a **home** feature (per user). Set it in `users/<user>/home.nix`.
  Because each user gets its own home-manager evaluation, two users on the same machine can differ.

**Every feature has a flag** (`enable`); only the _default_ differs. Four classes:

| class        | default                        | helper                | example                                  |
| ------------ | ------------------------------ | --------------------- | ---------------------------------------- |
| **plumbing** | — (no flag; unconditional)     | —                     | `base.nix`, `nixpkgs.nix`, `users.nix`   |
| **core**     | `true` (on unless disabled)    | `tools.opt.mkEnabled`  | `git`, `shell`, `fonts`, `secrets`      |
| **optional** | `false` (opt-in)               | `tools.opt.mkDisabled` | `games`, `desktopApps`, `vpn`, `fuse`   |
| **ride**     | = parent group's value         | `tools.opt.mkRiding p` | `dev.direnv`, `dev.editors.helix`       |

**Groups.** A group (e.g. `dev`) is a namespace: a master `my.user.dev.enable` plus sub-features
whose default _rides_ the master (`tools.opt.mkRiding config.my.user.dev.enable`). Flip the master and
the whole group follows; override any sub to carve it out. Mutually-optional members (e.g. the
`vscode` editor) are independent opt-ins, not ride-alongs.

**Flip a feature:**

```nix
# users/ipratt/home.nix — give the work user VS Code, drop the CLI utils group
my.user.dev.editors.vscode.enable = true;
my.user.utils.enable = false;

# hosts/glorpbook/default.nix — this host wants the VPN clients + games casks
my.sys.vpn.enable = true;
my.sys.games.enable = true;
```

**Value options: only what varies.** A module gets _value_ options (not just `enable`) only for
settings that differ per host/user — e.g. `my.user.git.{userName,email,signingKey,signByDefault}`
and `my.user.flakeDir`. Everything identical everywhere stays inline; modules with no per-machine
customization get just `.enable`.

**Where the helpers come from.** The `tools` argument (from `lib/opts.nix`) is passed to every module,
grouped by what it does: **`tools.opt.*`** — option constructors (`mkEnabled`/`mkDisabled`/`mkRiding`
plus `mkStr`/`mkNullStr`/`mkEnum` for value options, `mkSecretPath` for a secret hole, and `requires`
for cross-feature assertions); **`tools.secrets.*`** — agenix wiring (see [Secrets](#secrets)).
Uniform helpers mean every flag has the same shape.

**Safety.** Because every `my.*` leaf is _declared_ (never a freeform `attrsOf`), a typo like
`my.user.gmes.enable` fails evaluation with "option does not exist" — in any file. That strict
schema is the real guard; `tools.opt.requires` covers genuine cross-feature invariants ("A needs B").

The module tree under `modules/` is the source of truth for which features exist: each module's
`options.my.<scope>.<feature>` declaration (near its top) names its flag and class.

## Secrets

Sensitive material (a GPG key, a VPN profile, a token) is encrypted with [agenix] and committed under
`secrets/` — the `*.age` blobs are safe to push; only the matching **private age key** decrypts them.
Full workflow (create/edit/rotate, bootstrapping a machine, the GPG ceremony) lives in
**[`secrets/README.md`](secrets/README.md)**; the model in brief:

- **Identities are per-(user, machine).** Each machine generates its own age key at
  `/etc/nix/age/<user>` (never copied), registered in `secrets/recipients.nix` as `"<user>@<host>"`.
  A leaked key exposes only that one machine's secrets.
- **A secret's folder picks its audience** (resolved by `secrets/secrets.nix`): `cogs@glorpbook/…`
  → that machine only; `cogs/…` → every one of that user's machines. So "on all my boxes" is done by
  encrypting to multiple recipients, never by sharing a private key.
- **Features stay secret-agnostic.** A feature exposes a `tools.opt.mkSecretPath` hole; the user/host
  unit does the wiring — `age.secrets = tools.secrets.declare "<id>" "<name>"` to register it, and
  `tools.secrets.path config "<id>" "<name>"` to feed the decrypted path into the hole. So "which
  secret feeds which feature" lives in one file, the unit.

Example (git's signing key on a box provisioned via agenix):

```nix
# users/cogs/home.nix
age.secrets                = tools.secrets.declare "cogs@home-desktop" "gpg";
my.user.git.signingKeyFile = tools.secrets.path config "cogs@home-desktop" "gpg";
```

## Common tasks

```sh
# Rebuild / switch the current machine
rebuild # Alias of ./scripts/rebuild.sh

# Update flake inputs (bump flake.lock) and rebuild
upgrade # Alias of ./scripts/upgrade.sh

# Garbage-collect old generations
cleanup # Alias of ./scripts/cleanup.sh
```

> [!note]
>
> On nix-darwin, changing your login shell is manual. Run this command:
>
> ```sh
> chsh -s /run/current-system/sw/bin/<shell>
> ```

## Work desktop — standalone home-manager on Ubuntu

The work box runs Ubuntu 24 and is **not** NixOS: only the home-manager layer from this flake is
applied (`homeConfigurations."ipratt@work-desktop"`), so nothing here manages the OS itself.
Ubuntu stays exactly as-is; Nix simply lives alongside it under `/nix`.

### Which Nix install: multi-user (recommended) vs single-user

**Recommended: multi-user (daemon), installed via Determinate Nix.** On a dev machine you
administer with `sudo`, multi-user is the modern default and the better choice:

- Builds run as unprivileged `nixbld` users, isolated from your home directory — safer, and the
  upstream norm. Single-user (`--no-daemon`) is legacy (and unsupported on macOS).
- **Determinate Nix** — Determinate Systems' downstream Nix distribution, the same one the
  MacBook in this repo uses — adds, over vanilla Nix: flakes + `nix-command` enabled out of the
  box (no `nix.conf` editing), faster flake evaluation (`lazy-trees` + parallel eval), the
  FlakeHub binary cache, a robust installer **and uninstaller**, and a managed `/etc/nix/nix.conf`
  (`determinate-nixd`). It is multi-user only, which lines up with the recommendation above.
- Keeping the work box on Determinate matches the rest of this config.

Use single-user **only** if you do not have root on the machine.

Either way the flake is **install-method-agnostic**: `hosts/work-desktop` and the shared home
modules make no assumption about single vs multi-user. The `shell.nix` nix-env sourcing and the
`rebuild`/`cleanup` scripts handle both, and none of the aliases use `sudo` on this box.

#### Recommended — multi-user + Determinate Nix

```sh
# 1. Install Determinate Nix (multi-user; needs sudo). Flakes are on by default. As of early
#    2026 this installer always installs Determinate Nix — no flag needed.
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone this flake to /etc/nix (the path hosts/work-desktop expects — same location as the
#    system hosts, but owned by you rather than root since Nix here is a per-user install).
sudo mkdir -p /etc/nix && sudo chown "$(id -u):$(id -g)" /etc/nix
git clone <this-repo> /etc/nix

# 3. Apply it. The attribute is <primaryUser>@<hostName>, from hosts/work-desktop/id.nix. On a
#    fresh box `home-manager` isn't on PATH yet, so bootstrap the first switch via `nix run`:
nix run home-manager/release-26.05 -- switch -b bak --flake /etc/nix#ipratt@work-desktop \
    --print-build-logs
```

#### Alternative — single-user (no root)

```sh
# 1. Install Nix single-user (--no-daemon): the store is owned by you, no daemon, nothing in /etc.
sh <(curl -L https://nixos.org/nix/install) --no-daemon

# 2. Clone the flake.
git clone <this-repo> ~/.config/nix

# 3. Enable flakes for your user. ~/.config/nix/nix.conf is the per-user config file — it sits
#    inside the repo dir, but `nix.conf*` is gitignored so it is never committed.
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf

# 4. Apply it.
nix run home-manager/release-26.05 -- switch -b bak --flake ~/.config/nix#ipratt@work-desktop
```

After the first switch, `home-manager` is on `PATH`, so the usual aliases work:

```sh
rebuild   # ./scripts/rebuild.sh — detects standalone HM and runs `home-manager switch` (no sudo)
upgrade   # bump flake.lock + rebuild
cleanup   # expire old home-manager generations + gc
```

> [!note]
>
> **The work-box name is a single source of truth** — `hosts/work-desktop/id.nix` (`hostName` +
> `primaryUser`); see [the `id.nix` / `hostId` convention](#the-idnix--hostid-convention). The
> `homeConfigurations` attribute name and `home.username` both derive from it, so renaming the box
> is a one-file edit. `rebuild` doesn't hardcode or guess it either — it auto-discovers the flake's
> sole `homeConfigurations` entry (falling back to `$(whoami)@$(hostname)`, or an explicit
> `HM_TARGET` override).

> [!note]
>
> home-manager can't set your login shell on non-NixOS. To make fish the default (once):
>
> ```sh
> chsh -s ~/.nix-profile/bin/fish
> ```

> [!note]
>
> **Git credentials on Linux use libsecret, and the helper ships _inside_ the git package.** nixpkgs
> builds `git` on Linux with libsecret support, so the binary lives at
> `${pkgs.git}/bin/git-credential-libsecret` — no separate package to install. `git.nix` points
> `credential.helper` at it (instead of the plaintext `store` helper). It talks to the running
> Secret Service (gnome-keyring / KWallet), which Ubuntu's GNOME session provides out of the box.
> (git's old `git-credential-gnome-keyring` helper is deprecated in favour of libsecret.)

### Installing Nix on a non-NixOS machine (reference)

Kept here for future reference. On any non-NixOS host (Ubuntu, other distros, WSL, macOS) Nix
installs into `/nix` and leaves the OS's own package manager untouched — there are two installers:

|                | **Determinate Nix**                     | **Regular (upstream) Nix**                       |
| -------------- | --------------------------------------- | ------------------------------------------------ |
| Installer host | `install.determinate.systems/nix`       | `nixos.org/nix/install`                          |
| Mode           | multi-user only                         | `--daemon` (multi) **or** `--no-daemon` (single) |
| Flakes         | on by default                           | opt-in (via `nix.conf`)                          |
| Extras         | `lazy-trees`, FlakeHub cache, managed `/etc/nix/nix.conf` | —                              |
| Uninstall      | one command                             | manual                                           |

**Determinate Nix** — Determinate Systems' distribution (recommended; what this repo targets).
As of early 2026 the installer always installs Determinate Nix (the old `--prefer-upstream-nix`
opt-out was removed), so no flag is needed.

```sh
# Install (multi-user; needs sudo)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Uninstall (single command — also removes the installer itself)
/nix/nix-installer uninstall
```

**Regular (upstream) Nix** — the official installer from nixos.org. Pick the mode explicitly;
flakes are opt-in.

```sh
# Install, multi-user (daemon; recommended, needs sudo)
sh <(curl -L https://nixos.org/nix/install) --daemon

# Install, single-user (no daemon, no root — store owned by you)
sh <(curl -L https://nixos.org/nix/install) --no-daemon

# Enable flakes (upstream does not by default)
mkdir -p ~/.config/nix && echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

Uninstalling upstream Nix is manual:

```sh
# single-user: just remove the store (plus the Nix line the installer added to your shell profile)
rm -rf /nix

# multi-user (Linux + systemd):
sudo systemctl stop nix-daemon.service
sudo systemctl disable nix-daemon.socket nix-daemon.service
sudo systemctl daemon-reload
sudo rm -rf /nix /etc/nix /etc/profile.d/nix.sh /etc/tmpfiles.d/nix-daemon.conf \
    ~root/.nix-channels ~root/.nix-defexpr ~root/.nix-profile
for i in $(seq 1 32); do sudo userdel "nixbld$i"; done
sudo groupdel nixbld
# then remove any Nix lines from /etc/bash.bashrc, /etc/bashrc, /etc/profile, /etc/zshrc
# (the installer leaves *.backup-before-nix copies you can restore).
```

That fiddly upstream uninstall vs Determinate's one-liner is a large part of why Determinate is
recommended here. See the [Determinate uninstall docs][det-uninstall] and the
[upstream uninstall docs][nix-uninstall].

### Migrating the work box from single-user to multi-user

If you installed single-user and later want multi-user (daemon), the supported route is to
reinstall Nix — an in-place single→multi conversion is not supported. Nothing of value is lost:
your environment is declarative and rebuilt from this flake.

1. (Optional) note your current generation: `home-manager generations | head -1`.
2. Uninstall the single-user Nix: remove `/nix`, `~/.nix-profile`, `~/.nix-defexpr`,
   `~/.nix-channels`, and the Nix lines the installer appended to your shell profile (`~/.profile` /
   `~/.bash_profile`).
3. Reinstall multi-user — see the [install reference](#installing-nix-on-a-non-nixos-machine-reference)
   above. Prefer Determinate (flakes on by default, matches the rest of this config):
   `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`.
4. Move the repo from `~/.config/nix` to `/etc/nix` (the path the multi-user setup — and
   `users/ipratt`'s `my.user.flakeDir` — expects): `sudo mkdir -p /etc/nix && sudo chown
   "$(id -u):$(id -g)" /etc/nix && mv ~/.config/nix/* ~/.config/nix/.git /etc/nix/`.
5. Re-apply the config: `home-manager switch -b bak --flake /etc/nix#ipratt@work-desktop` (or
   just `rebuild`).

No changes to this repo are required beyond moving it. `rebuild` / `upgrade` / `cleanup` keep working on your user's
home-manager profile without `sudo` after the switch; `cleanup` deliberately never escalates on a
standalone box, so it only ever collects your own generations. If you moved to Determinate, its
daemon manages `/etc/nix/nix.conf` for you.

### `/etc/nix` vs `/etc/nixos` vs `~/.config/nix`

These are three different things that are easy to conflate (and the old scripts did):

| Path             | What it is                                                                               |
| ---------------- | ---------------------------------------------------------------------------------------- |
| `/etc/nix/`      | The **Nix daemon/CLI** config dir — home of `nix.conf`. Overridable via `NIX_CONF_DIR`.  |
| `/etc/nixos/`    | Where **NixOS** looks for `configuration.nix` / its flake (`nixos-rebuild`). NixOS-only. |
| `~/.config/nix/` | The **per-user** Nix config dir (a user-level `nix.conf`, XDG).                          |

None of these means "where my flake repo lives" — that's incidental. On the Mac and the work box
this repo happens to sit at `/etc/nix`, so repo-root and the nix.conf dir coincide there; on the
work box specifically `/etc/nix` is owned by the user (not root), since Nix is a per-user install.
The single-user alternative install path above still uses `~/.config/nix`, since a rootless
machine has no write access to `/etc` at all. Because of that, the scripts **derive the flake dir
from their own location** and never set `NIX_CONF_DIR` (doing so would tell Nix to read `nix.conf`
from the repo — wrong on
Ubuntu). Note `nix.conf`/`*.crt` are gitignored, so cloning to `~/.config/nix` carries no stray Nix
config into the user-config path.

## Resources

- [Nix & NixOS official docs](https://nixos.org/learn/) — the canonical entry point.
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/) — the best flakes-first
  walkthrough.
- [nix.dev](https://nix.dev/) — official tutorials, including a solid flakes intro.
- [Zero to Nix](https://zero-to-nix.com/) — Determinate Systems' beginner guide (matches the
  Determinate Nix used here).
- [nix-darwin manual](https://nix-darwin.github.io/nix-darwin/manual/) — every `darwin.*` option.
- [Home Manager manual](https://nix-community.github.io/home-manager/) — every `home.*` option.
- [MyNixOS](https://mynixos.com/) & [search.nixos.org](https://search.nixos.org/options) — search
  packages and options across nixpkgs / home-manager / nix-darwin.
- [nixos.wiki](https://nixos.wiki/) — practical how-tos and recipes.

[nixpkgs]: https://github.com/NixOS/nixpkgs
[nix-darwin]: https://github.com/nix-darwin/nix-darwin
[home-manager]: https://github.com/nix-community/home-manager
[determinate]: https://determinate.systems/nix/
[determinate-darwin]: https://docs.determinate.systems/guides/nix-darwin/
[agenix]: https://github.com/ryantm/agenix
[det-uninstall]: https://manual.determinate.systems/installation/uninstall.html
[nix-uninstall]: https://nix.dev/manual/nix/latest/installation/uninstall
