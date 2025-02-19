# Derived from https://github.com/ryan4yin/nix-darwin-kickstarter/blob/main/minimal/modules/apps.nix
{ pkgs, ... }: {
  ##########################################################################
  #
  #  Install all apps and packages here.
  #
  #  NOTE: Your can find all available options in:
  #    https://daiderd.com/nix-darwin/manual/index.html
  #
  # TODO Fell free to modify this file to fit your needs.
  #
  ##########################################################################

  # Allow unfree packages like discord
  nixpkgs.config.allowUnfree = true;

  # Install packages from nix's official package repository.
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  # NOTE: If a package isn't here, check the system-specific packages
  environment.systemPackages = with pkgs; [
    git
    gnupg
    neovim
    kitty
    discord # For some reason discord is availabe on mac via nixpkgs, but not firefox???
    fontconfig
    alejandra
    lazygit

    # Nodejs
    nodejs_23
    bun

    # Ruby
    rbenv

    # Rust
    rustup
  ];
}
