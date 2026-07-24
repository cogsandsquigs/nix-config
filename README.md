# nix-config

Personal NixOS / nix-darwin / home-manager config: a single-user, single-repo flake building a Mac,
a personal Linux desktop, and a standalone-home-manager work desktop.

## Overview

A **plain flake**. Every file under `modules/` is an ordinary NixOS / nix-darwin / home-manager
module, and **the directory tree _is_ the import graph** — each `default.nix` imports its siblings
and children, so a folder reads top-down as exactly what it pulls in.

Three hosts:

| Host                 | Class        | Platform         | Attribute                                   | User(s)            |
| -------------------- | ------------ | ---------------- | ------------------------------------------- | ------------------ |
| `glorpbook`          | nix-darwin   | `aarch64-darwin` | `darwinConfigurations."glorpbook"`          | `cogs` (personal)  |
| `home-desktop`       | NixOS        | `x86_64-linux`   | `nixosConfigurations.home-desktop`          | `cogs` (personal)  |
| `work-desktop`       | home-manager | `x86_64-linux`   | `homeConfigurations."ipratt@work-desktop"`  | `ipratt` (work)    |

The first two are **system** configs applied with `*-rebuild`. The third is **standalone
home-manager** on Ubuntu 24 — Nix per-user, no system layer, applied with `home-manager switch`.

**Two layers of selection:** a host picks _which users_ live on it; a user picks _which home
features_ it wants. Neither touches feature-module code — that's the whole design (see
[the `users/` layer](#the-users-layer) and [feature toggles](#feature-toggles)):

- **`hosts/<host>/`** — host selection: platform, host-only tweaks, its user units (`id.nix`'s
  `users`), and system features (`my.sys.<feature>.enable`).
- **`users/<user>/`** — a portable unit: one human's identity, home feature set
  (`my.user.<feature>.enable`), and (on full-OS hosts) system account. Droppable on any host by
  name. `cogs` enables the personal extras (games + GUI apps); `ipratt` leaves them off for a lean
  work profile with a work git identity.

Every user imports the **same full home library** (`modules/home`); `cogs` vs `ipratt` differ only
in which `my.user.*` flags they flip — no import-bundle split.

Key inputs (`flake.nix`): [nixpkgs] (stable), [nix-darwin], [home-manager], [Determinate
Nix][determinate], [sops-nix] for secrets.

## Structure

- **`flake.nix`** — inputs + outputs (the three host configs + formatter).
- **`flake.lock`** — pinned input revisions.
- **`tools/default.nix`** — the _only_ place that knows how a host is assembled:
  - `mkDarwin` / `mkNixos` / `mkHome` — build system or standalone home-manager hosts.
  - `forAllSystems` — map over systems for per-system outputs (e.g. the formatter).
  - `specialArgsFor` — the shared `specialArgs`/`extraSpecialArgs`: `inputs`, `hostId`, per-host `tools`.
- **`tools/opt.nix`** — option constructors + safety helpers (`tools.opt`).
- **`tools/secrets.nix`** — sops wiring helpers (`tools.secrets`).
- **`tools/conf.nix`** — config utilities (`tools.conf`, e.g. `eachOs` for per-OS branches). `tools`
  is a dedicated `specialArg`, not folded into `lib` — extending HM's `lib` clobbers `lib.hm.*`.
- **`hosts/`** — per-machine **selection**. Each host has an **`id.nix`**
  (`{ hostName; system; users; primaryUser; }`; see the
  [`id.nix` / `hostId` convention](#the-idnix--hostid-convention)) plus a `default.nix` for host-only
  tweaks. No user identity or feature logic here.
  - **`glorpbook/`** — darwin (dock, TouchID sudo, homebrew, launchd).
  - **`home-desktop/`** — personal NixOS.
  - **`work-desktop/`** — standalone home-manager (Ubuntu). Nothing host-specific beyond its
    `id.nix`; identity, git, and `my.user.flakeDir` live in the `ipratt` user unit.
- **`users/`** — per-user **isolated, portable units** (see [the `users/` layer](#the-users-layer)):
  `identity.nix` (plain data), `home.nix` (home feature set + git identity), `system.nix` (system
  account, full-OS hosts only).
  - **`cogs/`** — personal (full profile). **`ipratt/`** — work (lean core, work git identity, signing off).
- **`modules/`**
  - **`home-manager.nix`** — wires each `hostId.users` entry to its `users/<name>/home.nix` (system classes).
  - **`system/`** — system-level (system hosts only): **`common/`** (both classes: nixpkgs, shells),
    **`darwin/`** (macOS), **`nixos/`** (Linux).
  - **`home/`** — home-manager, class-agnostic; OS differences handled inline
    (`lib.optionals pkgs.stdenv.isDarwin …`). `default.nix` imports the **full feature library**;
    every module owns its own `my.user.<feature>.enable` flag ([feature toggles](#feature-toggles)):
    - **`base.nix`** — plumbing (stateVersion, home dir); no flag.
    - **`git.nix`, `ssh.nix`, `terminal.nix`** — core (on by default). `git.nix` also holds the
      identity/signing value options (`my.user.git.userName/email/signingKey/…`).
    - **`shell/`** — shell + prompt (core). Holds `my.user.flakeDir` and the
      [`.env` override loader](#local-env-overrides-env).
    - **`utils/`** — gpg, yazi, zellij, … (core group).
    - **`dev/`** — dev toolchain **group**: master `my.user.dev.enable` + ride-along sub-features
      (`ide`, `direnv`, `containers`, `langs/`, editors — `helix` on, `vscode` opt-in install-only).
    - **`games.nix`, `desktop-apps/`** — optional (off by default); `cogs` opts in.
- **`scripts/`** — wrappers `rebuild.sh`/`upgrade.sh`/`cleanup.sh`/`editnix.sh`. Location-independent
  (derive the flake dir from their own path) and auto-detect `darwin-rebuild` / `nixos-rebuild` /
  standalone `home-manager switch`.
- **`secrets/`** — sops-encrypted secrets + rules (`.sops.yaml`), `sops-stash.sh` / `mint-subkeys.sh`
  helpers, and a how-to `README.md`. See [Secrets](#secrets).
- **`nix.conf`** — Nix daemon settings.
- **`treefmt.toml`** — one-command repo formatting (`treefmt`); also nixfmt's `--width`/`--indent`
  (no native config file). Matches the helix formatter settings (4-space, 100 cols).
- **`.prettierrc.json`** — prettier options (4-space, 100 cols) for JSON/YAML/JS/CSS/…, picked up by
  prettier / prettierd (editor and `treefmt` alike).

### How a host is assembled

A **system** host: `flake.nix` calls e.g. `lib.mkDarwin ./hosts/glorpbook`, producing a system from
two module lists:

1. `modules/system/<class>` — shared system config for that OS. Its `default.nix` also imports
   `modules/system/common`, pulls in home-manager via `modules/home-manager.nix`, and declares
   system accounts via `system/<class>/users.nix`. Both iterate the host's `id.nix` `users`: each
   user's `home.nix` → a `home-manager.users.<name>` entry, each `system.nix` → a system account.
2. `./hosts/<name>` — the machine-specific bits.

The **standalone home-manager** host: `flake.nix` calls
`lib.mkHome { host = ./hosts/work-desktop; }`. No system layer — `mkHome` reads the host's single
user from `id.nix` and builds a `homeConfigurations` entry from `users/<user>/home.nix` + the host
file (setting `home.username`).

So **hosts pick users, users pick features** — a host never names a home feature, a user never names
a host. That split lets a user move machines (or a machine gain a second user) by editing only `id.nix`.

### The `users/` layer

Each `users/<name>/` is an **isolated, portable unit** — everything about one human account, with no
reference to any hostname or other user, so a host can place it by listing it in `id.nix`'s `users`.
Three files:

```
users/<name>/
  identity.nix   # plain-data attrset: { username = "cogs"; }. No module args — importable anywhere
                 # (flake output naming, standalone home.username) without the module system.
  home.nix       # home-manager module: imports the full home library (modules/home) and sets this
                 # user's my.user.* flags + values (features on/off, git identity, flakeDir).
  system.nix     # NixOS/darwin module: users.users.<name> account attrs. Full-OS hosts only;
                 # class-portable (NixOS-only attrs guarded behind pkgs.stdenv.isLinux).
```

The feature set is a property of the **user**, not the host: `users/cogs/home.nix` and
`users/ipratt/home.nix` import the same `modules/home` and differ only in the `my.user.*` flags they
set. Putting the work user on a personal machine = adding `"ipratt"` to that host's `users`; it
arrives as a distinct account with its own selection, not a "work profile" of `cogs`.

**Add a user:** create `users/<name>/{identity.nix,home.nix,system.nix}` (copy an existing unit),
import `modules/home` in `home.nix`, flip the `my.user.*` flags and set `my.user.git.*`, then add
`"<name>"` to the `users` list of the host(s) that should have it.

### The `id.nix` / `hostId` convention

Every host directory carries an **`id.nix`** — a plain attrset, the single source of truth for that
machine's **host** identity (user identity lives in `users/`):

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

1. **Into modules as `hostId`.** The builders `import` it and pass it via `specialArgs`; modules read
   it to drive per-host wiring without hardcoding names: `modules/home-manager.nix` → one
   `home-manager.users.<name>` per `hostId.users`; `system/{darwin,nixos}/users.nix` → imports
   `users/<name>/system.nix` per `hostId.users`; the host file → `networking.hostName`,
   `nixpkgs.hostPlatform`, and (glorpbook) `system.primaryUser` / homebrew owner from `primaryUser`.
2. **Into `flake.nix` for output names.** `flake.nix` reads each `id.nix` to form
   `darwinConfigurations.<hostName>`, `nixosConfigurations.<hostName>`,
   `homeConfigurations."<primaryUser>@<hostName>"`. `scripts/rebuild.sh` then _discovers_ the
   standalone name from the flake rather than hardcoding it.

**`primaryUser`** exists because some host-level singletons take exactly one user (nix-darwin's
`system.primaryUser`, the Homebrew prefix owner). Single-user host → just that user; multi-user →
whichever account owns those singletons.

**Naming:** fields are camelCase (`hostName`, `system`, `users`, `primaryUser`).

**Add a host:**

1. `hosts/<name>/id.nix` (`{ hostName; system; users; primaryUser; }`), listing existing or new
   ([the `users/` layer](#the-users-layer)) user units in `users`.
2. `hosts/<name>/default.nix` — machine-specific module. Pull identity from the `hostId` arg (don't
   re-`import ./id.nix`); no user/feature logic here.
3. Wire it in `flake.nix`: read its id (`idOf ./hosts/<name>`) and add the matching
   `darwinConfigurations` / `nixosConfigurations` / `homeConfigurations` entry via the right `lib.mk*`.

## Feature toggles

Every feature is an independent module that **owns its own `enable` flag**. Turning a feature on/off
for a host or user is one line in one file — you never touch the feature's module. This is the core
design goal.

**Two scopes:**

- **`my.sys.<feature>.enable`** — a **system** feature (per host), set in `hosts/<host>/default.nix`.
- **`my.user.<feature>.enable`** — a **home** feature (per user), set in `users/<user>/home.nix`.
  Each user gets its own home-manager evaluation, so two users on one machine can differ.

**Every feature has an `enable`**; only the _default_ differs. Four classes:

| class        | default                        | helper                 | example                                  |
| ------------ | ------------------------------ | ---------------------- | ---------------------------------------- |
| **plumbing** | — (no flag; unconditional)     | —                      | `base.nix`, `nixpkgs.nix`, `users.nix`   |
| **core**     | `true` (on unless disabled)    | `tools.opt.mkEnabled`  | `git`, `shell`, `fonts`, `secrets`       |
| **optional** | `false` (opt-in)               | `tools.opt.mkDisabled` | `games`, `desktopApps`, `vpn`, `fuse`    |
| **ride**     | = parent group's value         | `tools.opt.mkRiding p` | `dev.direnv`, `dev.editors.helix`        |

**Groups.** A group (e.g. `dev`) is a namespace: a master `my.user.dev.enable` plus sub-features
whose default _rides_ it (`tools.opt.mkRiding config.my.user.dev.enable`). Flip the master, the whole
group follows; override any sub to carve it out. Mutually-optional members (e.g. `vscode`) are
independent opt-ins, not ride-alongs.

**Flip a feature:**

```nix
# users/ipratt/home.nix — give the work user VS Code, drop the CLI utils group
my.user.dev.editors.vscode.enable = true;
my.user.utils.enable = false;

# hosts/glorpbook/default.nix — this host wants the VPN clients + games casks
my.sys.vpn.enable = true;
my.sys.games.enable = true;
```

**Value options: only what varies.** A module gets _value_ options (beyond `enable`) only for
settings that differ per host/user — e.g. `my.user.git.{userName,email,signingKey,signByDefault}`
and `my.user.flakeDir`. Everything identical everywhere stays inline.

**Helpers** come from `tools` (a per-host `specialArg`): **`tools.opt.*`** — option constructors
(`mkEnabled`/`mkDisabled`/`mkRiding`, `mkStr`/`mkEnum`, `mkSecretPath`, `requires`);
**`tools.secrets.*`** — sops wiring; **`tools.conf.*`** — config utilities (`eachOs`).

**Safety.** Every `my.*` leaf is _declared_ (never a freeform `attrsOf`), so a typo like
`my.user.gmes.enable` fails evaluation with "option does not exist". That strict schema is the real
guard; `tools.opt.requires` covers genuine cross-feature invariants ("A needs B").

The module tree under `modules/` is the source of truth for which features exist — each module's
`options.my.<scope>.<feature>` declaration (near its top) names its flag and class.

## Secrets

Sensitive material (a GPG key, VPN profile, token) is encrypted with [sops-nix] and committed under
`secrets/` — the `*.sops` blobs are safe to push; only the matching **private age key** decrypts them.
Full workflow (create/edit/rotate, bootstrapping, the GPG ceremony) is in
**[`secrets/README.md`](secrets/README.md)**; in brief:

- **Identities are per-(user, machine).** Each machine generates its own age key at
  `/etc/nix/age/<user>` (never copied), registered in `secrets/.sops.yaml` as a rule's recipient.
  A leaked key exposes only that machine's secrets.
- **A secret's folder picks its audience** (via the `creation_rules` in `secrets/.sops.yaml`):
  `cogs@glorpbook/…` → that machine only; `cogs/…` → all of that user's machines. "On all my boxes" =
  encrypt to multiple recipients, never share a private key.
- **Features stay secret-agnostic.** A feature exposes a `tools.opt.mkSecretPath` hole; the user/host
  unit wires it — `sops.secrets = tools.secrets.declare "<id>" "<name>"` to register,
  `tools.secrets.path config "<id>" "<name>"` to feed the decrypted path in. So "which secret feeds
  which feature" lives in one file, the unit.

```nix
# users/cogs/home.nix — git's signing key on a box provisioned via sops
sops.secrets               = tools.secrets.declare "cogs@home-desktop" "gpg";
my.user.git.signingKeyFile = tools.secrets.path config "cogs@home-desktop" "gpg";
```

## Local env overrides (`.env`)

`${flakeDir}/.env` (i.e. `/etc/nix/.env` on every current host) is a machine-local, git-ignored
`KEY=VALUE` file sourced at shell startup — **after** the config sets its env vars, **before** PATH
is built. It overrides anything the `variables` set in `modules/home/shell/shell.nix` define, and an
overridden `JAVA_HOME` still feeds `$JAVA_HOME/bin`. A missing file is a no-op.

- **No rebuild to change values.** The shells re-read `.env` on every startup, so editing a value
  there takes effect in the next shell — no `rebuild`. (Adding the *mechanism* needed a rebuild;
  changing values in `.env` does not.)
- **One parser.** bash/zsh source it directly (`set -a; . .env; set +a`); fish reuses bash via the
  `bass` plugin — so bash quoting rules apply everywhere (quote values with spaces).
- **Typical use:** the work box sets `JAVA_HOME=/usr/lib/jdk-21` to prefer a locally-installed JDK
  over the Nix one, instead of hardcoding it in the flake.

## Common tasks

```sh
rebuild   # ./scripts/rebuild.sh — rebuild / switch the current machine
upgrade   # ./scripts/upgrade.sh — bump flake.lock + rebuild
cleanup   # ./scripts/cleanup.sh — garbage-collect old generations
```

> [!note]
>
> On nix-darwin, changing your login shell is manual:
>
> ```sh
> chsh -s /run/current-system/sw/bin/<shell>
> ```

## Work desktop — standalone home-manager on Ubuntu

The work box runs Ubuntu 24, **not** NixOS: only the home-manager layer
(`homeConfigurations."ipratt@work-desktop"`) is applied, so nothing here manages the OS. Ubuntu stays
as-is; Nix lives alongside it under `/nix`.

### Which Nix install: multi-user (recommended) vs single-user

**Recommended: multi-user (daemon) via Determinate Nix.** On a machine you administer with `sudo`,
multi-user is the modern default:

- Builds run as unprivileged `nixbld` users, isolated from `$HOME` — safer, the upstream norm.
  Single-user (`--no-daemon`) is legacy (and unsupported on macOS).
- **Determinate Nix** (Determinate Systems' distribution, same as this repo's MacBook) adds over
  vanilla: flakes + `nix-command` on by default, faster eval (`lazy-trees` + parallel), the FlakeHub
  cache, a robust installer **and uninstaller**, and a managed `/etc/nix/nix.conf`
  (`determinate-nixd`). Multi-user only — lines up with the recommendation.
- Keeps the work box matching the rest of this config.

Use single-user **only** without root.

Either way the flake is **install-method-agnostic**: `hosts/work-desktop` and the home modules make
no single/multi-user assumption. The `shell.nix` nix-env sourcing and the scripts handle both, and no
alias uses `sudo` here.

#### Recommended — multi-user + Determinate Nix

```sh
# 1. Install Determinate Nix (multi-user; needs sudo). Flakes on by default. As of early 2026 this
#    installer always installs Determinate Nix — no flag needed.
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone to /etc/nix (the path hosts/work-desktop expects — same as the system hosts, but owned by
#    you rather than root, since Nix here is a per-user install).
sudo mkdir -p /etc/nix && sudo chown "$(id -u):$(id -g)" /etc/nix
git clone <this-repo> /etc/nix

# 3. Apply. Attribute is <primaryUser>@<hostName> from hosts/work-desktop/id.nix. On a fresh box
#    `home-manager` isn't on PATH yet, so bootstrap the first switch via `nix run`:
nix run home-manager/release-26.05 -- switch -b bak --flake /etc/nix#ipratt@work-desktop \
    --print-build-logs
```

#### Alternative — single-user (no root)

```sh
# 1. Install Nix single-user (--no-daemon): store owned by you, no daemon, nothing in /etc.
sh <(curl -L https://nixos.org/nix/install) --no-daemon

# 2. Clone the flake.
git clone <this-repo> ~/.config/nix

# 3. Enable flakes for your user. ~/.config/nix/nix.conf sits inside the repo dir, but `nix.conf*`
#    is gitignored so it's never committed.
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf

# 4. Apply.
nix run home-manager/release-26.05 -- switch -b bak --flake ~/.config/nix#ipratt@work-desktop
```

After the first switch, `home-manager` is on `PATH`, so the usual aliases work (`rebuild` / `upgrade`
/ `cleanup`, all sudo-free on this box).

> [!note]
>
> **The work-box name is a single source of truth** — `hosts/work-desktop/id.nix` (`hostName` +
> `primaryUser`; see [the `id.nix` / `hostId` convention](#the-idnix--hostid-convention)). The
> `homeConfigurations` attribute and `home.username` both derive from it, so renaming the box is a
> one-file edit. `rebuild` auto-discovers the flake's sole `homeConfigurations` entry (falling back
> to `$(whoami)@$(hostname)`, or an explicit `HM_TARGET`).

> [!note]
>
> home-manager can't set your login shell on non-NixOS. Make fish default (once):
>
> ```sh
> chsh -s ~/.nix-profile/bin/fish
> ```

> [!note]
>
> **Git credentials on Linux use libsecret, shipped _inside_ the git package.** nixpkgs builds `git`
> on Linux with libsecret support, so `${pkgs.git}/bin/git-credential-libsecret` exists with no
> separate package. `git.nix` points `credential.helper` at it (not the plaintext `store` helper); it
> talks to the running Secret Service (gnome-keyring / KWallet), which Ubuntu's GNOME session
> provides. (git's old `git-credential-gnome-keyring` is deprecated in favour of libsecret.)

### Installing Nix on a non-NixOS machine (reference)

On any non-NixOS host (Ubuntu, other distros, WSL, macOS) Nix installs into `/nix` and leaves the
OS's package manager untouched. Two installers:

|                | **Determinate Nix**                     | **Regular (upstream) Nix**                       |
| -------------- | --------------------------------------- | ------------------------------------------------ |
| Installer host | `install.determinate.systems/nix`       | `nixos.org/nix/install`                          |
| Mode           | multi-user only                         | `--daemon` (multi) **or** `--no-daemon` (single) |
| Flakes         | on by default                           | opt-in (via `nix.conf`)                          |
| Extras         | `lazy-trees`, FlakeHub cache, managed `/etc/nix/nix.conf` | —                              |
| Uninstall      | one command                             | manual                                           |

**Determinate Nix** (recommended; what this repo targets). As of early 2026 the installer always
installs Determinate Nix (the old `--prefer-upstream-nix` opt-out was removed) — no flag needed.

```sh
# Install (multi-user; needs sudo)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Uninstall (one command — also removes the installer itself)
/nix/nix-installer uninstall
```

**Regular (upstream) Nix** — official installer from nixos.org. Pick the mode explicitly; flakes are
opt-in.

```sh
# Multi-user (daemon; recommended, needs sudo)
sh <(curl -L https://nixos.org/nix/install) --daemon

# Single-user (no daemon, no root — store owned by you)
sh <(curl -L https://nixos.org/nix/install) --no-daemon

# Enable flakes (upstream doesn't by default)
mkdir -p ~/.config/nix && echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

Uninstalling upstream Nix is manual:

```sh
# single-user: remove the store (plus the Nix line the installer added to your shell profile)
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
# (the installer leaves *.backup-before-nix copies to restore).
```

That fiddly upstream uninstall vs Determinate's one-liner is much of why Determinate is recommended.
See the [Determinate uninstall docs][det-uninstall] and [upstream uninstall docs][nix-uninstall].

### Migrating the work box from single-user to multi-user

An in-place single→multi conversion isn't supported — reinstall. Nothing of value is lost; the
environment is declarative and rebuilt from this flake.

1. (Optional) note your current generation: `home-manager generations | head -1`.
2. Uninstall single-user Nix: remove `/nix`, `~/.nix-profile`, `~/.nix-defexpr`, `~/.nix-channels`,
   and the Nix lines the installer appended to your shell profile (`~/.profile` / `~/.bash_profile`).
3. Reinstall multi-user — see the [install reference](#installing-nix-on-a-non-nixos-machine-reference).
   Prefer Determinate:
   `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`.
4. Move the repo from `~/.config/nix` to `/etc/nix` (the path the multi-user setup and
   `users/ipratt`'s `my.user.flakeDir` expect): `sudo mkdir -p /etc/nix && sudo chown
   "$(id -u):$(id -g)" /etc/nix && mv ~/.config/nix/* ~/.config/nix/.git /etc/nix/`.
5. Re-apply: `home-manager switch -b bak --flake /etc/nix#ipratt@work-desktop` (or `rebuild`).

No repo changes needed beyond moving it. `rebuild`/`upgrade`/`cleanup` keep working sudo-free on your
home-manager profile; `cleanup` never escalates on a standalone box (collects only your generations).
On Determinate, its daemon manages `/etc/nix/nix.conf`.

### `/etc/nix` vs `/etc/nixos` vs `~/.config/nix`

Three easily-conflated things (the old scripts did):

| Path             | What it is                                                                               |
| ---------------- | ---------------------------------------------------------------------------------------- |
| `/etc/nix/`      | The **Nix daemon/CLI** config dir — home of `nix.conf`. Overridable via `NIX_CONF_DIR`.  |
| `/etc/nixos/`    | Where **NixOS** looks for `configuration.nix` / its flake (`nixos-rebuild`). NixOS-only. |
| `~/.config/nix/` | The **per-user** Nix config dir (user-level `nix.conf`, XDG).                            |

None means "where my flake repo lives" — that's incidental. On the Mac and work box this repo sits at
`/etc/nix` (so repo-root and the nix.conf dir coincide; on the work box `/etc/nix` is user-owned, not
root, since Nix is per-user). The single-user install path uses `~/.config/nix`, since a rootless
machine can't write `/etc`. So the scripts **derive the flake dir from their own location** and never
set `NIX_CONF_DIR` (which would tell Nix to read `nix.conf` from the repo — wrong on Ubuntu).
`nix.conf`/`*.crt` are gitignored, so cloning to `~/.config/nix` carries no stray Nix config there.

## Resources

- [Nix & NixOS official docs](https://nixos.org/learn/) — canonical entry point.
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/) — best flakes-first walkthrough.
- [nix.dev](https://nix.dev/) — official tutorials, incl. a solid flakes intro.
- [Zero to Nix](https://zero-to-nix.com/) — Determinate Systems' beginner guide (matches the
  Determinate Nix used here).
- [nix-darwin manual](https://nix-darwin.github.io/nix-darwin/manual/) — every `darwin.*` option.
- [Home Manager manual](https://nix-community.github.io/home-manager/) — every `home.*` option.
- [MyNixOS](https://mynixos.com/) & [search.nixos.org](https://search.nixos.org/options) — search
  packages/options across nixpkgs / home-manager / nix-darwin.
- [nixos.wiki](https://nixos.wiki/) — practical how-tos.

[nixpkgs]: https://github.com/NixOS/nixpkgs
[nix-darwin]: https://github.com/nix-darwin/nix-darwin
[home-manager]: https://github.com/nix-community/home-manager
[determinate]: https://determinate.systems/nix/
[determinate-darwin]: https://docs.determinate.systems/guides/nix-darwin/
[sops-nix]: https://github.com/Mic92/sops-nix
[det-uninstall]: https://manual.determinate.systems/installation/uninstall.html
[nix-uninstall]: https://nix.dev/manual/nix/latest/installation/uninstall
