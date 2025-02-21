# Derived from https://github.com/ryan4yin/nix-darwin-kickstarter/blob/main/minimal/modules/apps.nix
{pkgs, ...}: {
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

  # Install packages from nix's official package repository.
  # NOTE: see ./apps.nix, contains global packages
  # NOTE: This is really only here for *very* specific packages
  environment.systemPackages = with pkgs; [
    raycast
    net-news-wire
    skimpdf
    pinentry_mac
    mkalias
    # zapzap # Open source whatsapp alt.
    # whatsapp-for-mac
    # Unfortunately, due to this error: https://github.com/NixOS/nixpkgs/issues/364195,
    # I am not able to install this. So homebrew :/
  ];

  # TODO To make this work, homebrew need to be installed manually, see https://brew.sh
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap"; # 'zap': uninstalls all formulae(and related files) not listed here.
    };

    taps = [
      "homebrew/services"
    ];

    # `brew install`
    # TODO Feel free to add your favorite apps here.
    brews = [
      # "aria2"  # download tool
    ];

    masApps = {
      "Xcode" = 497799835;
    };

    # `brew install --cask`
    # TODO Feel free to add your favorite apps here.
    casks = [
      # "firefox" # For some reason, not provided w/ nixos for aarch64-darwin
      "whatsapp"
      "tailscale"
      "steam"
    ];
  };
}
