# nix

My nix configuration!

## Layout

- `flake.nix`: The flake that specifies how to load each system configuration
  for each OS/arch type
- `system`: System configuration, including applications and such
  - `system/all`: configuration for all systems.
  - `system/darwin`: MacOS configuration
- `home`: Home-Manager configuration, used to configure dotfiles and such. This is where things like the shell, programs
  with configuration in `~/.config`, etc. are configured. Each separate program should have it's own
  `home/config/<program-name>.nix` file (see `home/git.nix`, etc.). Some things package-only may be in `home/config/packages/<file>.nix`

> [!NOTE]
> The only exception for this are programming languages, which have their own file in `home/packages/languages/<language>.nix`

### What's the difference between `modules/apps.nix`, `modules/<platform>/apps.nix`, and `home/home.nix:packages`?

- `modules/apps.nix` are _global_ applications installed for _all users_. If it contains a GUI, not
  platform-dependent, and/or isn't just a userland tweak, it should go here. `modules/<platform>/apps.nix` is for any applications that can't be installed on all platforms/only installed on
  some platforms. Otherwise, it's the same as `modules/apps.nix`
- `home/home.nix:packages` are userland tweaks and small packages like shells and `git`. If it doesn't have a GUI/is a
  CLI, shouldn't be globally installed, or is configured with `home-manager`, it should go here.
- `scripts` is where utility scripts live.

## Notes (for me!)

- Old brew stuff is in `Brewfile`
- In order to keep a global standard for C/C++ formatting, but _also allow local overrides if desired_ (e.g. formatting
  standard for group project), we specify a `.clang-format` that's copied to the home directory in
  `home/neovim/.clang-format`. For local control, specify a `.clang-format` in the local directory.
- Since `nix-darwin` is a bit jank, to set a shell other than `zsh` you need to run `chsh -s /run/current-system/sw/bin/<shell>`.

## Resources

- [Set up Nix on macOS using flakes, nix-darwin and home-manager](https://noghartt.dev/blog/set-up-nix-on-macos-using-flakes-nix-darwin-and-home-manager/)
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)
- [This example](https://github.com/AlexNabokikh/nix-config/blob/master/flake.nix)
