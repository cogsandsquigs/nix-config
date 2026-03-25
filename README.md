# nix

My nix configuration! This setup is primarily used for myself and my own (single-user) devices.

This follows the [Dendritic Nix Pattern], to allow clean organization of my files and such. There
are 3 main _classes_ within this configuration:

- **`flake.modules.nixos`**: The configuration for a nixos setup.
- **`flake.modules.darwin`**: The configuration for a darwin setup.
- **`flake.modules.homeManager`**: The configuration home-manager, to manage all of my dotfiles.

> [!info]
>
> The `flake.` just represents outputs from this entire flake. Accessing `flake.<whatever>` just
> gives you the output made by `<whatever>`, or allows you to define it.

## Files and File-tree Layout

Each `.nix` file in `modules` defines an _aspect_ that is used within this flake. There are a few
specific directories within `modules` that are special:

- **`modules/lib`**: Defines common libraries used across flakes.
- **`modules/tools`**: Defines tools/"add-ons" to base nixos/nix-darwin (i.e. home-manager).
- **`modules/hosts`**: Defines machine specifications and operating systems, and produces the
  end-point `flake.nixosConfigurations`/`flake.darwinConfigurations` for each host in `hosts`.
- **`modules/users`**: Defines specific users for my machines. Currently, only has `cogs`.
- **`modules/systems`**: Defines systems that configure machines (i.e., `base`, `desktop`)
- **`modules/programs`**: Defines programs used across machines.

## Aspects

There are several _aspects_ used to configure systems. Some of these are (TODO: Make full list!):

> [!info]
>
> `.*` means this aspect applies to all classes (`nixos`, `darwin`, and `home-manager`).
>
> `.<A/B>` means this aspect applies to classes `A` and `B`.

- **`flake.modules.<nixos/darwin>.base`**: Base system setup, barely anything except what is needed
  to get up and go.

- **`flake.modules.<nixos/darwin>.desktop`**: Desktop system setup, depends on `base`. Sets up a
  desktop environment to my liking.

## Notes (for me!)

- In order to keep a global standard for C/C++ formatting, but _also allow local overrides if
  desired_ (e.g. formatting standard for group project), we specify a `.clang-format` that's copied
  to the home directory in `home/neovim/.clang-format`. For local control, specify a `.clang-format`
  in the local directory.
- Since `nix-darwin` is a bit jank, to set a shell other than `zsh` you need to run
  `chsh -s /run/current-system/sw/bin/<shell>`.

## Resources

- [Dendritic Nix](https://dendrix.oeiuwq.com/Dendritic.html)
- [Dendritic Design with the Flake Parts Framework](https://github.com/Doc-Steve/dendritic-design-with-flake-parts)
- [Ultimate NixOS Desktop: Niri, Noctalia Shell, and the Dendritic Pattern | Full Setup](https://www.youtube.com/watch?v=aNgujRXDTdE)
- [Set up Nix on macOS using flakes, nix-darwin and home-manager](https://noghartt.dev/blog/set-up-nix-on-macos-using-flakes-nix-darwin-and-home-manager/)
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)
- [This example](https://github.com/AlexNabokikh/nix-config/blob/master/flake.nix)
