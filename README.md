# nix

My nix configuration!

## Notes (for me!)

- In order to keep a global standard for C/C++ formatting, but _also allow local overrides if desired_ (e.g. formatting
  standard for group project), we specify a `.clang-format` that's copied to the home directory in
  `home/neovim/.clang-format`. For local control, specify a `.clang-format` in the local directory.
- Since `nix-darwin` is a bit jank, to set a shell other than `zsh` you need to run `chsh -s /run/current-system/sw/bin/<shell>`.

## Resources

- [Dendritic Design with the Flake Parts Framework](https://github.com/Doc-Steve/dendritic-design-with-flake-parts)
- [Ultimate NixOS Desktop: Niri, Noctalia Shell, and the Dendritic Pattern | Full Setup](https://www.youtube.com/watch?v=aNgujRXDTdE)
- [Set up Nix on macOS using flakes, nix-darwin and home-manager](https://noghartt.dev/blog/set-up-nix-on-macos-using-flakes-nix-darwin-and-home-manager/)
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)
- [This example](https://github.com/AlexNabokikh/nix-config/blob/master/flake.nix)
