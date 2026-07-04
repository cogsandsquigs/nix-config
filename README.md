# nix

My personal NixOS / nix-darwin configuration! A single-user, single-repo flake that builds both a
Mac and a Linux desktop.

## Overview

This is a **plain flake**. Every file under `modules/` is an ordinary NixOS / nix-darwin /
home-manager module, and **the directory tree _is_ the import graph**: each `default.nix` imports
its siblings and children, so you can read a folder top-down to see exactly what it pulls in.

Two hosts are built:

| Host                 | Class      | Platform         | Attribute                                   |
| -------------------- | ---------- | ---------------- | ------------------------------------------- |
| `Ians-GlorpBook-Pro` | nix-darwin | `aarch64-darwin` | `darwinConfigurations."Ians-GlorpBook-Pro"` |
| `desktop`            | NixOS      | `x86_64-linux`   | `nixosConfigurations.desktop`               |

Key inputs (see `flake.nix`): [nixpkgs] (unstable), [nix-darwin], [home-manager],
[Determinate Nix][determinate], and [agenix] for secrets.

## Structure

- **`flake.nix`** — Inputs + outputs. Declares the two host configurations and the formatter.
- **`flake.lock`** — Pinned input revisions.
- **`lib/default.nix`** — The _only_ place that knows how a host is assembled:
  - `mkDarwin` / `mkNixos` — build a host from `./hosts/<name>` + `modules/system/<class>`.
  - `forAllSystems` — map over systems for per-system outputs (e.g. the formatter).
- **`hosts/`** — Per-machine identity: hostname, `hostPlatform`, host-only tweaks.
  - **`macbook/`** — darwin host (dock, TouchID sudo, homebrew, launchd).
  - **`desktop/`** — nixos host.
- **`modules/`**
  - **`home-manager.nix`** — Wires the `cogs` user to `./home`; shared by both classes.
  - **`system/`** — System-level config.
    - **`common/`** — Valid on BOTH classes (nixpkgs settings, shells).
    - **`darwin/`** — macOS-only (`default.nix` imports `common` + everything here).
    - **`nixos/`** — Linux-only.
  - **`home/`** — home-manager config for `cogs`, class-agnostic. OS differences handled inline
    (`lib.optionals pkgs.stdenv.isDarwin ...`).
    - **`base.nix`, `git.nix`, `ssh.nix`, `terminal.nix`, …** — top-level aspects.
    - **`shell/`** — Shell + prompt.
    - **`utils/`** — gpg, yazi, zellij, …
    - **`desktop-apps/`** — Browser, GUI apps.
    - **`dev/`** — Editor, direnv, containers, and `langs/` (per-language tooling).
- **`scripts/`** — Convenience wrappers: `rebuild.sh`, `upgrade.sh`, `cleanup.sh`, `editnix.sh`.
- **`secrets/`** — agenix-encrypted secrets (consumed as a flake input).
- **`nix.conf`** — Nix daemon settings.

### How a host is assembled

`flake.nix` calls `lib.mkDarwin ./hosts/macbook`, which produces a system from two module lists:

1. `modules/system/<class>` — the shared system config for that OS. Its `default.nix` also imports
   `modules/system/common` and pulls in home-manager via `modules/home-manager.nix`.
2. `./hosts/<name>` — the machine-specific bits.

Home config lives once under `modules/home` and is shared across both hosts.

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
