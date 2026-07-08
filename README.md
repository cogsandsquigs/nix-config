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
- **`hosts/`** — Per-machine identity: hostname, `hostPlatform`/`home.username`, host-only tweaks.
  - **`macbook/`** — darwin host (dock, TouchID sudo, homebrew, launchd).
  - **`home-desktop/`** — personal NixOS host.
  - **`work-desktop/`** — standalone home-manager host (Ubuntu). Sets `home.username`, points
    `my.flakeDir` at `~/.config/nix`, and overrides `my.git` for the work identity.
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

The work box is **not** NixOS, and Nix is installed as a **single-user** install (the store is owned
by your user, there is no `nix-daemon`, and nothing under `/etc` is touched). Only the home-manager
layer is applied. First-time setup:

```sh
# 1. Install Nix, SINGLE-USER (--no-daemon). Store is owned by you; no root daemon.
sh <(curl -L https://nixos.org/nix/install) --no-daemon

# 2. Clone this flake to ~/.config/nix (the path hosts/work-desktop expects).
git clone <this-repo> ~/.config/nix

# 3. Enable flakes for your user. ~/.config/nix/nix.conf is the per-user Nix config file — it
#    lives inside the repo dir, but `nix.conf*` is gitignored so it is never committed.
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf

# 4. Apply it. The attribute is username@hostname.
nix run home-manager/release-26.05 -- switch -b bak --flake ~/.config/nix#ipratt@work-desktop
```

After that first switch, `home-manager` is on `PATH`, so the usual aliases just work — and none of
them use `sudo` on this box, matching the single-user install:

```sh
rebuild   # ./scripts/rebuild.sh — detects standalone HM and runs `home-manager switch` (no sudo)
upgrade   # bump flake.lock + rebuild
cleanup   # expire old home-manager generations + gc
```

The flake itself is **install-method-agnostic**: nothing in `hosts/work-desktop` or the shared home
modules assumes single- vs multi-user, so moving between them (below) needs no config changes. The
nix-env sourcing in `shell.nix` and the rebuild/cleanup scripts already handle both layouts.

> [!note]
>
> The flake attribute is `ipratt@work-desktop`. `rebuild` derives the target from
> `$(whoami)@$(hostname)`, so either set the machine's hostname to `work-desktop`, or export
> `HM_TARGET=ipratt@work-desktop`.

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

### Migrating the work box from single-user to multi-user

If you later want the multi-user (daemon) install on this machine, the supported route is to
reinstall Nix in multi-user mode — an in-place single→multi conversion is not supported. Nothing of
value is lost: your environment is declarative and rebuilt from this flake.

1. (Optional) note your current generation: `home-manager generations | head -1`.
2. Uninstall the single-user Nix: remove `/nix`, `~/.nix-profile`, `~/.nix-defexpr`,
   `~/.nix-channels`, and the Nix lines the installer appended to your shell profile (`~/.profile` /
   `~/.bash_profile`).
3. Reinstall multi-user: `sh <(curl -L https://nixos.org/nix/install) --daemon`.
4. Re-enable flakes for your user if the line was removed:
   `echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf`.
5. Re-apply the config: `home-manager switch -b bak --flake ~/.config/nix#ipratt@work-desktop` (or
   just `rebuild`).

No changes to this repo are required. `rebuild` / `upgrade` / `cleanup` keep working on your user's
home-manager profile without `sudo` after the switch; `cleanup` deliberately never escalates on a
standalone box, so it only ever collects your own generations.

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
