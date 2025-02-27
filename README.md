# nix

My nix configuration!

## Layout

- `modules`: Split configuration, including applications and such
  - `modules/darwin`: MacOS configuration
- `home`: Home-Manager configuration, used to configure dotfiles and such. This is where things like the shell, programs
  with configuration in `~/.config`, etc. are configured. Each separate program should have it's own
  `home/<program-name>.nix` file (see `home/git.nix`, etc.).

### What's the difference between `modules/apps.nix`, `modules/<platform>/apps.nix`, and `home/home.nix:packages`?

- `modules/apps.nix` are _global_ applications installed for _all users_. If it contains a GUI, not
  platform-dependent, and/or isn't just a userland tweak, it should go here. `modules/<platform>/apps.nix` is for any applications that can't be installed on all platforms/only installed on
  some platforms. Otherwise, it's the same as `modules/apps.nix`
- `home/home.nix:packages` are userland tweaks and small packages like shells and `git`. If it doesn't have a GUI/is a
  CLI, shouldn't be globally installed, or is configured with `home-manager`, it should go here.
- `scripts` is where utility scripts live.

## Notes (for me!)

- Old brew stuff is in `Brewfile`

## Resources

- [Set up Nix on macOS using flakes, nix-darwin and home-manager](https://noghartt.dev/blog/set-up-nix-on-macos-using-flakes-nix-darwin-and-home-manager/)
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)
- [This example](https://github.com/AlexNabokikh/nix-config/blob/master/flake.nix)
