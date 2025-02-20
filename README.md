# nix

My nix configuration!

## Layout

- `modules`: Split configuration, including applications and such
  - `modules/darwin`: MacOS configuration
- `home`: Home-Manager configuration, used to configure dotfiles and such. This is where things like the shell, programs
  with configuration in `~/.config`, etc. are configured.

## Notes (for me!)

- Old brew stuff is in `Brewfile`

## Resources

- [Set up Nix on macOS using flakes, nix-darwin and home-manager](https://noghartt.dev/blog/set-up-nix-on-macos-using-flakes-nix-darwin-and-home-manager/)
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)
