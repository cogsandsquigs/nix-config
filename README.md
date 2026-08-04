# nix-config

Personal NixOS / nix-darwin / home-manager config: a single-user, single-repo flake building a Mac,
a personal Linux desktop, and a standalone-home-manager work desktop.

## Overview

A plain flake with one framework dependency. `import-tree` walks `modules/`, and the module system
does everything else: it checks the class of every file, the schema of every host, and the placement
of every option.

Three machines:

| Host           | Class        | Platform         | Output                                     | User(s)           |
| -------------- | ------------ | ---------------- | ------------------------------------------ | ----------------- |
| `glorpbook`    | nix-darwin   | `aarch64-darwin` | `darwinConfigurations.glorpbook`           | `cogs` (personal) |
| `home-desktop` | NixOS        | `x86_64-linux`   | `nixosConfigurations.home-desktop`         | `cogs` (personal) |
| `work-desktop` | home-manager | `x86_64-linux`   | `homeConfigurations."ipratt@work-desktop"` | `ipratt` (work)   |

The first two are system configurations, applied with `*-rebuild`. The third is standalone
home-manager on Ubuntu: Nix per user, no system layer, applied with `home-manager switch`.

Selection happens at two levels, and neither one touches a feature's own code. A host picks which
users live on it. A user picks which home features it wants.

- **`hosts/<host>/`** holds `id.nix`, the machine's typed identity, and `default.nix` for settings
  only that machine needs.
- **`users/<user>/`** holds one person's home configuration and, on a full-OS host, their system
  account. Drop a user on any machine by naming them in that host's `users`.

`cogs` turns on the personal extras. `ipratt` leaves them off and sets a work git identity.

Key inputs: [nixpkgs], [nix-darwin], [home-manager], [Determinate Nix][determinate], [sops-nix] for
secrets, and [import-tree] for module discovery.

## Repository layout

- **`flake.nix`** — inputs, and outputs derived from the fleet. It names no machine.
- **`tools/`** — the only code that knows how a host is assembled.
    - `default.nix` — the three builders and the module-argument contract.
    - `fleet.nix` — the typed schema for `hosts/` and `users/`.
    - `registry.nix` — turns `modules/` into per-class module sets.
    - `feature.nix` — path to feature name, shared by the registry and the `feature-paths` check.
    - `checks.nix` — the gates.
    - `opt.nix` — option constructors. `secrets.nix` — sops wiring.
    - `_fixtures/` — module trees and host stubs for `tools-tests`.
- **`modules/`** — every feature. One file per feature, keyed by class. See
  [Module layout](#module-layout).
- **`hosts/`** — per-machine identity and host-only settings.
- **`users/`** — per-user home configuration and system account.
- **`secrets/`** — sops-encrypted material and the rules that address it. See [Secrets](#secrets).
- **`scripts/`** — `nxm`, the one rebuild/upgrade/clean/edit entry point.
- **`treefmt.toml`**, **`.prettierrc.json`**, **`statix.toml`** — formatting and lint configuration.
- **`nix.conf`** — Nix daemon settings.

## Module layout

Every `.nix` file under `modules/` is one feature. The path names the feature. The file is an
attribute set, keyed by the classes the feature covers:

```nix
# modules/apps/games.nix
{
    home = { ... };   # a home-manager module
    nixos = { ... };  # a NixOS module
    darwin = { ... }; # a nix-darwin module
}
```

A feature that covers one class has one key. Every file is keyed the same way, so a feature that
gains a class later gains a key. No file is renamed for it, and no reader has to know which form a
given feature uses.

The classes share one `let` block, so a value two of them need is written once. This is why
`modules/sys/nix.nix` states the substituter list one time instead of once per system class.

The key `options` is reserved. It declares the options that **every** class in the file declares, so
a feature states them one time:

```nix
{
    options = { tools, ... }: { my.sys.net.tailscale.enable = tools.opt.mkDisabled "Tailscale"; };

    nixos = { lib, config, ... }: { config = lib.mkIf ... ; };
    darwin = { lib, config, ... }: { config = lib.mkIf ... ; };
}
```

A class may still declare options of its own, and the two sets merge. They must not overlap: one
option declared twice is an error from the module system, and the message names the file twice.

Options shared by some classes but not all stay in a `let` block instead. `modules/secrets.nix`
declares `my.sys.secrets.enable` in its two system halves only. As a shared `options` block it would
reach the home evaluation as well, where nothing reads `my.sys` and nothing should.

A directory adds a level to the feature name. `modules/dev/ai/mcp/gerrit.nix` is the feature
`dev.ai.mcp.gerrit`, and that feature owns the option path `my.user.dev.ai.mcp.gerrit`. A grouping
folder is therefore a real namespace: `modules/cli/git.nix` owns `my.user.cli.git`, not
`my.user.git`. `modules/sys/` is the exception in reverse — it holds the plumbing that declares no
options at all, because `my.sys.sys` would stutter.

A folder's own feature is its `default.nix`, which names no extra level:
`modules/dev/ai/default.nix` is the feature `dev.ai`, and it owns `my.user.dev.ai`. This is the same
thing `default.nix` already means in `hosts/<host>/` and in `tools/` — the thing the folder _is_ —
and it keeps a group beside the children it groups, so `ls modules/dev/ai/` is the whole feature. A
leaf feature is `<name>.nix`; give it a folder and the file becomes `<name>/default.nix`, with no
option renamed. `import-tree` hands the loader the file path, so Nix's own folder-resolves-to-
`default.nix` rule never comes into it — `tools/feature.nix` drops the segment itself.

That makes `modules/cli/utils.nix` and `modules/cli/utils/default.nix` two paths for one feature, so
`tools/registry.nix` types the registry as `attrsOf (uniq deferredModule)`. Two files claiming one
feature is then "is defined multiple times while it's expected to be unique", naming the feature,
instead of a silent merge that would leave `feature-paths` comparing against whichever file it saw
first. The error surfaces as soon as a host evaluates, so `fleet-eval` catches it under
`nix flake check`.

A name that starts with `_` is not a module. Use it for shared values, package definitions, and data
tables. The loader skips these files. `modules/dev/_langs/` holds the language tables, and
`modules/dev/ai/mcp/_gerrit-package.nix` holds a package definition.

The path is binding, not advisory. The `feature-paths` check reads the file that declares each
`my.*` option and compares that file to the path. A file may only declare options under the feature
its path owns. To move a feature, move the file and rename its options in one commit. Either change
alone fails the build.

Three feature names are camelCase — `desktopApps`, `systemDefaults`, `appsFix` — because a path
mirrors its option path and those options were already camelCase.

## The registry

`import-tree` walks `modules/` and passes each path to `tools/registry.nix`. The registry reads the
feature name from the path and the classes from the file's own keys, then wraps each class:

```nix
{ _class = "nixos"; _file = <path>; imports = [ <the shared options> <the class key> ]; }
```

`_class` makes the module system reject the module if it reaches an evaluation of another class, and
the error names the file. `_file` stays the bare path, which is what `feature-paths` compares each
option's declaration against.

The registry collects these entries in a module evaluation with three options, one per class. Each
option has the type `attrsOf deferredModule`. An unknown class key fails as "option does not exist".
An entry that is not a module fails as a type error. Both errors come from the module system rather
than from hand-written validation.

`tools/default.nix` reads the registry and gives each class its own list. A NixOS host gets
`registry.nixos`. A nix-darwin host gets `registry.darwin`. Every home-manager evaluation gets
`registry.homeManager`.

The registry is also a flake output. Run `nix flake show` to list every feature and its class. The
attributes are `nixosModules`, `darwinModules`, and `homeModules`.

## Host and user data

`hosts/<name>/id.nix` holds three values and nothing else:

```nix
{
    class = "darwin";
    system = "aarch64-darwin";
    users = [ "cogs" ];
}
```

`tools/fleet.nix` checks these values against a schema before the flake builds anything. The schema
uses types instead of assertions, so an error names the option that is wrong.

- `class` selects the builder. The three values are `nixos`, `darwin`, and `home`.
- `system` must suit the class. A `darwin` host cannot take a Linux platform.
- `users` must name directories that exist under `users/`. A typo is a type error.
- `primaryUser` must be one of this host's own users. It defaults to the first entry, which is all a
  single-user host needs. It exists because some host-level settings take exactly one user, such as
  nix-darwin's `system.primaryUser` and the Homebrew prefix owner.

The host name comes from the directory name, and `id.nix` cannot set it. `flake.nix` reads the fleet
and builds one output for each host, so `flake.nix` never names a machine.

A user directory holds `home.nix`, and on a full-OS host also `system.nix`. The registry already
loads every feature, so `home.nix` imports nothing: it is pure selection. `system.nix` is keyed by
class, because the two classes accept different account attributes.

## Feature toggles

Every feature owns its own `enable` flag, so turning one on or off is one line in one file and never
touches the feature's own code.

There are two scopes. `my.sys.<feature>.enable` is a system feature, set per host.
`my.user.<feature>.enable` is a home feature, set per user. Each user gets their own home-manager
evaluation, so two users on one machine can differ.

Every feature has an `enable`. Only the default differs.

| Class        | Default                    | Constructor                | Example                                        |
| ------------ | -------------------------- | -------------------------- | ---------------------------------------------- |
| **plumbing** | none; always on            | —                          | `base`, `nixpkgs`, `users`                     |
| **core**     | `true`, on unless disabled | `tools.opt.mkEnabled`      | `git`, `shell`, `fonts`, `secrets`             |
| **optional** | `false`, opt-in            | `tools.opt.mkDisabled`     | `dev.editors.vscode`, `fuse`                   |
| **ride**     | follows its parent group   | `tools.opt.mkRiding p`     | `dev.direnv`, `dev.editors.helix`              |
| **follows**  | follows this host's users  | `tools.opt.mkFollowsUsers` | `my.sys.apps.games`, `my.sys.apps.desktopApps` |

A group such as `dev` is a namespace: a master `my.user.dev.enable` plus sub-features whose default
rides it. Flip the master and the whole group follows. Override any sub-feature to carve it out.

`mkFollowsUsers` removes a double flip. A machine needs Steam at the system level only because a
user on it plays games, so `my.sys.apps.games.enable` defaults to "some user on this host enabled
`my.user.apps.games`". This works because home-manager runs as a submodule of the system evaluation.
It is one-directional: a home feature must never read `my.sys.*` back, or the two evaluations would
deadlock.

Value options exist only for settings that differ between hosts or users, such as
`my.user.cli.git.userName` and `my.user.shell.flakeDir`. Anything identical everywhere stays inline.

Every `my.*` leaf is declared, never a free-form attribute set, so a typo like `my.user.gmes.enable`
fails evaluation with "option does not exist". `tools.opt.requires` covers cross-feature invariants
of the form "A needs B".

## Checks

Run every check from any machine in the fleet:

```sh
nix flake check
```

| Check             | It fails when                                                                   |
| ----------------- | ------------------------------------------------------------------------------- |
| `fleet-eval`      | A host stops evaluating, including a host this machine cannot build.            |
| `feature-paths`   | A file declares a `my.*` option outside the feature its path owns.              |
| `typed-options`   | A `my.*` option has no description, or uses a type that carries no information. |
| `tools-tests`     | A unit test over `tools/` fails.                                                |
| `lint`            | `statix` reports a finding.                                                     |
| `comment-density` | A module body is more than 20% comment.                                         |
| `fmt`             | The tree is not formatted, markdown included.                                   |

`fleet-eval` forces the derivation path of every host and then discards the string context. The
check therefore never builds a derivation for another platform. One command on the work desktop
proves that the MacBook configuration still evaluates.

`typed-options` rejects the types `attrs`, `anything`, `raw`, and `unspecified`, and follows
composite types inward, so `attrsOf attrs` is caught too. A few values are free-form because they
belong to a foreign schema, such as a language server's own settings. `tools/checks.nix` lists those
exceptions by name, so the list stays short and visible.

`comment-density` caps comments at 20% of a file, counting only the body: a file's leading comment
block is its documentation and is exempt, as is any file under 40 lines, where the ratio says
nothing. `tools/` is out of scope, since its doc comments are unrestricted. Four files are recorded
exceptions with their reasons, and the check also fails when one of them stops needing its
exception.

`fmt` runs the same `treefmt.toml` that `nix fmt` and a bare `treefmt` do, so the editor, the CLI
and the gate cannot disagree about formatting. Markdown is included, and prettier owns `.md` in both
the gate and the editor: dprint fetches its markdown plugin over the network, which a Nix sandbox
has no access to.

`nix flake check` also builds every feature in the registry, which proves each one evaluates on its
own and not only as part of a host.

## Add a feature

1. Choose the option path the feature owns, for example `my.user.dev.rust`.
2. Create the file at the matching path, for example `modules/dev/rust.nix`.
3. Key the file by the classes the feature covers, one key even for one class.
4. Declare the `enable` option with a `tools.opt` constructor.
5. Put the rest of the module under `lib.mkIf cfg.enable`.
6. Run `nix flake check`.

Do not edit any other file. The loader finds the new file.

## Add a host

1. Create `hosts/<name>/id.nix` with `class`, `system`, and `users`.
2. Create `hosts/<name>/default.nix` for the settings only this machine needs.
3. Run `nix flake check`.

Do not edit `flake.nix`. The directory name becomes the host name.

## Add a user

1. Create `users/<name>/home.nix` and set the `my.user.*` flags for this person.
2. If the host runs NixOS or nix-darwin, create `users/<name>/system.nix` for the account.
3. Add `"<name>"` to the `users` list of each host that gets the account.
4. Run `nix flake check`.

## Move or rename a feature

1. Move the file to the new path.
2. Rename its options to match the new path.
3. Run `nix flake check`.

Step 1 without step 2 fails `feature-paths`. Step 2 without step 1 fails the same check.

## Secrets

Sensitive material (a GPG key, a token, a certificate) is encrypted with [sops-nix] and committed
under `secrets/` -- the `*.sops` blobs are safe to push; only the matching **private age key**
decrypts them. Full workflow (create/edit/rotate, bootstrapping, the GPG ceremony) is in
**[`secrets/README.md`](secrets/README.md)**; in brief:

- **Identities are per-(user, machine).** Each machine generates its own age key at
  `/etc/nix/age/<user>` (never copied), registered in `secrets/.sops.yaml` as a rule's recipient. A
  leaked key exposes only that machine's secrets.
- **A secret's folder picks its audience** (via the `creation_rules` in `secrets/.sops.yaml`):
  `cogs@glorpbook/...` -> that machine only; `cogs/...` -> all of that user's machines. "On all my
  boxes" = encrypt to multiple recipients, never share a private key.
- **Features stay secret-agnostic.** A feature exposes a `tools.opt.mkSecretPath` hole; the
  user/host unit wires it -- `sops.secrets = tools.secrets.declare "<id>" "<name>"` to register,
  `tools.secrets.path config "<id>" "<name>"` to feed the decrypted path in. So "which secret feeds
  which feature" lives in one file, the unit.

```nix
# users/cogs/home.nix -- git's signing key on a box provisioned via sops
sops.secrets               = tools.secrets.declare "cogs@home-desktop" "gpg";
my.user.cli.git.signingKeyFile = tools.secrets.path config "cogs@home-desktop" "gpg";
```

## Local env overrides (`.env`)

`${flakeDir}/.env` (i.e. `/etc/nix/.env` on every current host) is a machine-local, git-ignored
`KEY=VALUE` file sourced at shell startup -- **after** the config sets its env vars, **before** PATH
is built. It overrides anything the `variables` set in `modules/shell/env.nix` define, and an
overridden `JAVA_HOME` still feeds `$JAVA_HOME/bin`. A missing file is a no-op.

- **No rebuild to change values.** The shells re-read `.env` on every startup, so editing a value
  there takes effect in the next shell -- no `nxm rebuild`. (Adding the _mechanism_ needed a
  rebuild; changing values in `.env` does not.)
- **One parser.** bash/zsh source it directly (`set -a; . .env; set +a`); fish reuses bash via the
  `bass` plugin -- so bash quoting rules apply everywhere (quote values with spaces).
- **Typical use:** the work box sets `JAVA_HOME=/usr/lib/jdk-21` to prefer a locally-installed JDK
  over the Nix one, instead of hardcoding it in the flake.
- **Credentials for MCP servers.** `my.user.dev.ai.mcp.*` defaults to `${GERRIT_HOST}`,
  `${GERRIT_USERNAME}`, `${GERRIT_PASSWORD}` (an HTTP password: Gerrit -> Settings -> HTTP
  Credentials) and `${YOUTRACK_HOST}`, `${YOUTRACK_AUTH_TOKEN}` (a permanent token, YouTrack scope).
  Claude Code expands them at launch, so they stay out of `/nix/store`. Only shells load `.env`, so
  a `claude` started from a desktop launcher can't reach either server.

## Common tasks

`nxm` (`scripts/nxm.py`, aliased in every shell) is the one entry point. Each subcommand has a
one-letter alias.

```sh
nxm rebuild   # r -- stage, commit, pull, rebuild / switch the current machine, push
nxm upgrade   # u -- bump flake.lock, then rebuild
nxm clean     # c -- garbage-collect old generations
nxm edit      # e -- open $EDITOR, then rebuild
```

> [!note]
>
> On nix-darwin, changing your login shell is manual:
>
> ```sh
> chsh -s /run/current-system/sw/bin/<shell>
> ```

## Work desktop -- standalone home-manager on Ubuntu

The work box runs Ubuntu 24, **not** NixOS: only the home-manager layer
(`homeConfigurations."ipratt@work-desktop"`) is applied, so nothing here manages the OS. Ubuntu
stays as-is; Nix lives alongside it under `/nix`.

Being a distro Linux is also what lets `my.user.dev.nvm.enable` work here: nvm downloads prebuilt
glibc node binaries, and Ubuntu provides the FHS loader they need. The `nvm.sh` script is pinned in
the store by `modules/dev/nvm.nix`; only the node versions it installs are imperative, under
`~/.nvm`. `node` stays the nixpkgs one until `nvm use` says otherwise.

### Which Nix install: multi-user (recommended) vs single-user

**Recommended: multi-user (daemon) via Determinate Nix.** On a machine you administer with `sudo`,
multi-user is the modern default:

- Builds run as unprivileged `nixbld` users, isolated from `$HOME` -- safer, the upstream norm.
  Single-user (`--no-daemon`) is legacy (and unsupported on macOS).
- **Determinate Nix** (Determinate Systems' distribution, same as this repo's MacBook) adds over
  vanilla: flakes + `nix-command` on by default, faster eval (`lazy-trees` + parallel), the FlakeHub
  cache, a robust installer **and uninstaller**, and a managed `/etc/nix/nix.conf`
  (`determinate-nixd`). Multi-user only -- lines up with the recommendation.
- Keeps the work box matching the rest of this config.

Use single-user **only** without root.

Either way the flake is **install-method-agnostic**: `hosts/work-desktop` and the home modules make
no single/multi-user assumption. The `modules/shell/env.nix` nix-env sourcing and `nxm` handle both,
and no alias uses `sudo` here.

#### Recommended -- multi-user + Determinate Nix

```sh
# 1. Install Determinate Nix (multi-user; needs sudo). Flakes on by default. As of early 2026 this
#    installer always installs Determinate Nix -- no flag needed.
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone to /etc/nix (the path hosts/work-desktop expects -- same as the system hosts, but owned by
#    you rather than root, since Nix here is a per-user install).
sudo mkdir -p /etc/nix && sudo chown "$(id -u):$(id -g)" /etc/nix
git clone <this-repo> /etc/nix

# 3. Apply. The attribute is <primaryUser>@<directory name> -- see hosts/work-desktop/. On a fresh box
#    `home-manager` isn't on PATH yet, so bootstrap the first switch via `nix run`:
nix run home-manager/release-26.05 -- switch -b bak --flake /etc/nix#ipratt@work-desktop \
    --print-build-logs
```

#### Alternative -- single-user (no root)

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

After the first switch, `home-manager` is on `PATH`, so `nxm rebuild` / `upgrade` / `clean` all
work, sudo-free on this box.

> [!note]
>
> **The work-box name is a single source of truth** -- the `hosts/work-desktop/` directory name,
> plus `primaryUser` from its `id.nix` (see [Host and user data](#host-and-user-data)). The
> `homeConfigurations` attribute and `home.username` both derive from it, so renaming the box is a
> one-file edit. `nxm` auto-discovers the flake's sole `homeConfigurations` entry (falling back to
> `$(whoami)@$(hostname)`, or an explicit `HM_TARGET`).

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
> separate package. `git.nix` points `credential.helper` at it (not the plaintext `store` helper);
> it talks to the running Secret Service (gnome-keyring / KWallet), which Ubuntu's GNOME session
> provides. (git's old `git-credential-gnome-keyring` is deprecated in favour of libsecret.)

### Installing Nix on a non-NixOS machine (reference)

On any non-NixOS host (Ubuntu, other distros, WSL, macOS) Nix installs into `/nix` and leaves the
OS's package manager untouched. Two installers:

|                | **Determinate Nix**                                       | **Regular (upstream) Nix**                       |
| -------------- | --------------------------------------------------------- | ------------------------------------------------ |
| Installer host | `install.determinate.systems/nix`                         | `nixos.org/nix/install`                          |
| Mode           | multi-user only                                           | `--daemon` (multi) **or** `--no-daemon` (single) |
| Flakes         | on by default                                             | opt-in (via `nix.conf`)                          |
| Extras         | `lazy-trees`, FlakeHub cache, managed `/etc/nix/nix.conf` | --                                               |
| Uninstall      | one command                                               | manual                                           |

**Determinate Nix** (recommended; what this repo targets). As of early 2026 the installer always
installs Determinate Nix (the old `--prefer-upstream-nix` opt-out was removed) -- no flag needed.

```sh
# Install (multi-user; needs sudo)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Uninstall (one command -- also removes the installer itself)
/nix/nix-installer uninstall
```

**Regular (upstream) Nix** -- official installer from nixos.org. Pick the mode explicitly; flakes
are opt-in.

```sh
# Multi-user (daemon; recommended, needs sudo)
sh <(curl -L https://nixos.org/nix/install) --daemon

# Single-user (no daemon, no root -- store owned by you)
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

An in-place single->multi conversion isn't supported -- reinstall. Nothing of value is lost; the
environment is declarative and rebuilt from this flake.

1. (Optional) note your current generation: `home-manager generations | head -1`.
2. Uninstall single-user Nix: remove `/nix`, `~/.nix-profile`, `~/.nix-defexpr`, `~/.nix-channels`,
   and the Nix lines the installer appended to your shell profile (`~/.profile` /
   `~/.bash_profile`).
3. Reinstall multi-user -- see the
   [install reference](#installing-nix-on-a-non-nixos-machine-reference). Prefer Determinate:
   `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`.
4. Move the repo from `~/.config/nix` to `/etc/nix` (the path the multi-user setup and
   `users/ipratt`'s `my.user.shell.flakeDir` expect):
   `sudo mkdir -p /etc/nix && sudo chown "$(id -u):$(id -g)" /etc/nix && mv ~/.config/nix/* ~/.config/nix/.git /etc/nix/`.
5. Re-apply: `home-manager switch -b bak --flake /etc/nix#ipratt@work-desktop` (or `nxm rebuild`).

No repo changes needed beyond moving it. `nxm rebuild`/`upgrade`/`clean` keep working sudo-free on
your home-manager profile; `clean` never escalates on a standalone box (collects only your
generations). On Determinate, its daemon manages `/etc/nix/nix.conf`.

### `/etc/nix` vs `/etc/nixos` vs `~/.config/nix`

Three easily-conflated things (the old scripts did):

| Path             | What it is                                                                               |
| ---------------- | ---------------------------------------------------------------------------------------- |
| `/etc/nix/`      | The **Nix daemon/CLI** config dir -- home of `nix.conf`. Overridable via `NIX_CONF_DIR`. |
| `/etc/nixos/`    | Where **NixOS** looks for `configuration.nix` / its flake (`nixos-rebuild`). NixOS-only. |
| `~/.config/nix/` | The **per-user** Nix config dir (user-level `nix.conf`, XDG).                            |

None means "where my flake repo lives" -- that's incidental. On the Mac and work box this repo sits
at `/etc/nix` (so repo-root and the nix.conf dir coincide; on the work box `/etc/nix` is user-owned,
not root, since Nix is per-user). The single-user install path uses `~/.config/nix`, since a
rootless machine can't write `/etc`. So `nxm` **derives the flake dir from its own location** and
never set `NIX_CONF_DIR` (which would tell Nix to read `nix.conf` from the repo -- wrong on Ubuntu).
`nix.conf`/`*.crt` are gitignored, so cloning to `~/.config/nix` carries no stray Nix config there.

## Resources

- [Nix & NixOS official docs](https://nixos.org/learn/) -- canonical entry point.
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/) -- best flakes-first walkthrough.
- [nix.dev](https://nix.dev/) -- official tutorials, incl. a solid flakes intro.
- [Zero to Nix](https://zero-to-nix.com/) -- Determinate Systems' beginner guide (matches the
  Determinate Nix used here).
- [nix-darwin manual](https://nix-darwin.github.io/nix-darwin/manual/) -- every `darwin.*` option.
- [Home Manager manual](https://nix-community.github.io/home-manager/) -- every `home.*` option.
- [MyNixOS](https://mynixos.com/) & [search.nixos.org](https://search.nixos.org/options) -- search
  packages/options across nixpkgs / home-manager / nix-darwin.
- [nixos.wiki](https://nixos.wiki/) -- practical how-tos.

[nixpkgs]: https://github.com/NixOS/nixpkgs
[nix-darwin]: https://github.com/nix-darwin/nix-darwin
[home-manager]: https://github.com/nix-community/home-manager
[determinate]: https://determinate.systems/nix/
[determinate-darwin]: https://docs.determinate.systems/guides/nix-darwin/
[sops-nix]: https://github.com/Mic92/sops-nix
[import-tree]: https://github.com/vic/import-tree
[det-uninstall]: https://manual.determinate.systems/installation/uninstall.html
[nix-uninstall]: https://nix.dev/manual/nix/latest/installation/uninstall
