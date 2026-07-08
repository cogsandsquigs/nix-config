# nix

My personal NixOS / nix-darwin / home-manager configuration! A single-user, single-repo flake that
builds a Mac, a personal Linux desktop, and a standalone-home-manager work desktop.

## Overview

This is a **plain flake**. Every file under `modules/` is an ordinary NixOS / nix-darwin /
home-manager module, and **the directory tree _is_ the import graph**: each `default.nix` imports
its siblings and children, so you can read a folder top-down to see exactly what it pulls in.

Three hosts are built:

| Host                 | Class        | Platform         | Attribute                                   | Profile             |
| -------------------- | ------------ | ---------------- | ------------------------------------------- | ------------------- |
| `Ians-GlorpBook-Pro` | nix-darwin   | `aarch64-darwin` | `darwinConfigurations."Ians-GlorpBook-Pro"` | personal (full)     |
| `home-desktop`       | NixOS        | `x86_64-linux`   | `nixosConfigurations.home-desktop`          | personal (full)     |
| `work-desktop`       | home-manager | `x86_64-linux`   | `homeConfigurations."ipratt@work-desktop"`  | core (develop-only) |

The first two are **system** configs (nix-darwin / NixOS) applied with `*-rebuild`. The third is a
**standalone home-manager** config for a work machine (Ubuntu 24) where Nix is installed per-user —
there is no system layer, and it's applied with `home-manager switch`.

**Profiles.** The home config is split so a machine picks how much of it to take:

- `modules/home` (core) — the "develop + as-needed" baseline: shell, terminal, CLI utils, and the
  full dev toolchain. This is all the **work** box gets.
- `modules/home/personal.nix` — core **plus** games and personal GUI apps (Discord, Obsidian, …).
  The **personal** machines (MacBook, home-desktop) get this.

Key inputs (see `flake.nix`): [nixpkgs] (stable), [nix-darwin], [home-manager],
[Determinate Nix][determinate], and [agenix] for secrets.

## Structure

- **`flake.nix`** — Inputs + outputs. Declares the two host configurations and the formatter.
- **`flake.lock`** — Pinned input revisions.
- **`lib/default.nix`** — The _only_ place that knows how a host is assembled:
  - `mkDarwin` / `mkNixos` — build a **system** host from `./hosts/<name>` +
    `modules/system/<class>`.
  - `mkHome` — build a **standalone home-manager** host from `./hosts/<name>` + `modules/home` (the
    core profile). Owns its own `pkgs` (allowUnfree/qt) since there's no system layer.
  - `forAllSystems` — map over systems for per-system outputs (e.g. the formatter).
- **`hosts/`** — Per-machine config. Each host has an **`id.nix`** (`{ userName; hostName; }` —
  the single source of truth for its identity; see the [`id.nix` / `hostId`
  convention](#the-idnix--hostid-convention)) plus a `default.nix` for host-only tweaks.
  - **`macbook/`** — darwin host (dock, TouchID sudo, homebrew, launchd).
  - **`home-desktop/`** — personal NixOS host.
  - **`work-desktop/`** — standalone home-manager host (Ubuntu). Points `my.flakeDir` at
    `~/.config/nix` and overrides `my.git` for the work identity.
- **`modules/`**
  - **`home-manager.nix`** — Wires the `cogs` user to `./home/personal.nix`; used by the two system
    classes.
  - **`system/`** — System-level config (only the system hosts use this).
    - **`common/`** — Valid on BOTH classes (nixpkgs settings, shells).
    - **`darwin/`** — macOS-only (`default.nix` imports `common` + everything here).
    - **`nixos/`** — Linux-only.
  - **`home/`** — home-manager config, class-agnostic. OS differences handled inline
    (`lib.optionals pkgs.stdenv.isDarwin ...`).
    - **`default.nix`** — the **core** profile (imported by every machine).
    - **`personal.nix`** — core + `games.nix` + `desktop-apps/` (the personal machines).
    - **`options.nix`** — custom `my.*` options (`my.flakeDir`, `my.git.*`) hosts flip to differ
      from the shared defaults.
    - **`base.nix`, `git.nix`, `ssh.nix`, `terminal.nix`, …** — top-level aspects.
    - **`shell/`** — Shell + prompt.
    - **`utils/`** — gpg, yazi, zellij, …
    - **`desktop-apps/`** — Browser, GUI apps (personal only).
    - **`dev/`** — Editor, direnv, containers, and `langs/` (per-language tooling).
- **`scripts/`** — Convenience wrappers: `rebuild.sh`, `upgrade.sh`, `cleanup.sh`, `editnix.sh`.
  Location-independent (they derive the flake dir from their own path) and auto-detect whether to
  use `darwin-rebuild` / `nixos-rebuild` / standalone `home-manager switch`.
- **`secrets/`** — agenix-encrypted secrets (consumed as a flake input).
- **`nix.conf`** — Nix daemon settings.

### How a host is assembled

For a **system** host, `flake.nix` calls e.g. `lib.mkDarwin ./hosts/macbook`, which produces a
system from two module lists:

1. `modules/system/<class>` — the shared system config for that OS. Its `default.nix` also imports
   `modules/system/common` and pulls in home-manager via `modules/home-manager.nix` (which loads the
   full personal profile, `modules/home/personal.nix`).
2. `./hosts/<name>` — the machine-specific bits.

For the **standalone home-manager** host, `flake.nix` calls
`lib.mkHome { host = ./hosts/work-desktop; }`. There is no system layer: `mkHome` builds a
`homeConfigurations` entry directly from `modules/home` (the **core** profile) + the host file.

Home config lives once under `modules/home`; the core is shared by every machine, and `personal.nix`
layers the personal-only extras on top for the personal machines.

### The `id.nix` / `hostId` convention

Every host directory carries an **`id.nix`** — a plain attrset that is the single source of truth
for that machine's identity:

```nix
# hosts/<name>/id.nix
{
    userName = "cogs";          # the machine's primary user account
    hostName = "home-desktop";  # the machine's hostname
}
```

It flows through the config in exactly two ways, so the name is never repeated:

1. **Into the modules as `hostId`.** The builders in `lib/default.nix` (`mkDarwin` / `mkNixos` /
   `mkHome`) `import` the host's `id.nix` and pass it via `specialArgs`/`extraSpecialArgs` as the
   `hostId` argument. Any module can then take `{ hostId, ... }` and read `hostId.userName` /
   `hostId.hostName`. This is why the shared modules never hardcode a user:
   - `modules/system/{darwin,nixos}/users.nix` → `users.users.${hostId.userName}`
   - `modules/home-manager.nix` → `home-manager.users.${hostId.userName}`
   - the host file itself → e.g. `networking.hostName = hostId.hostName` (system hosts),
     `home.username = hostId.userName` (standalone home-manager host).
2. **Into `flake.nix` for the output attribute names.** `flake.nix` reads each `id.nix` to form
   `darwinConfigurations.<hostName>`, `nixosConfigurations.<hostName>`, and
   `homeConfigurations."<userName>@<hostName>"`. `scripts/rebuild.sh` then *discovers* the
   standalone name from the flake rather than hardcoding it.

**Naming:** fields are camelCase (`userName`, `hostName`) — matching `my.git.userName` and
`networking.hostName`. Keep both fields in that one style.

**To add a new host:**

1. `mkdir hosts/<name>` and write `hosts/<name>/id.nix` (`{ userName; hostName; }`).
2. Write `hosts/<name>/default.nix` — the machine-specific module. Pull identity from the
   `hostId` argument (don't re-`import ./id.nix`); set the platform (`nixpkgs.hostPlatform`) for a
   system host, and any `my.*` overrides.
3. Wire it up in `flake.nix`: read its id (`idOf ./hosts/<name>`) and add the matching
   `darwinConfigurations` / `nixosConfigurations` / `homeConfigurations` entry via the right
   `lib.mk*` builder.

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

# 2. Clone this flake to ~/.config/nix (the path hosts/work-desktop expects).
git clone <this-repo> ~/.config/nix

# 3. Apply it. The attribute is <userName>@<hostName>, from hosts/work-desktop/id.nix.
nix run home-manager/release-26.05 -- switch -b bak --flake ~/.config/nix#ipratt@work-desktop
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
> **The work-box name is a single source of truth** — `hosts/work-desktop/id.nix` (`userName` +
> `hostName`); see [the `id.nix` / `hostId` convention](#the-idnix--hostid-convention). The
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
4. Re-apply the config: `home-manager switch -b bak --flake ~/.config/nix#ipratt@work-desktop` (or
   just `rebuild`).

No changes to this repo are required. `rebuild` / `upgrade` / `cleanup` keep working on your user's
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

None of these means "where my flake repo lives" — that's incidental. On the Mac this repo happens to
sit at `/etc/nix`, so repo-root and the nix.conf dir coincide; on the work box the repo sits at
`~/.config/nix`. Because of that, the scripts **derive the flake dir from their own location** and
never set `NIX_CONF_DIR` (doing so would tell Nix to read `nix.conf` from the repo — wrong on
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
