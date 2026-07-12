# Nix itself on darwin is managed by Determinate Nix, not nix-darwin.
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Substituters allow us to skip building configuration by downloading prebuilt outputs.
  substituters = [
    "https://cache.nixos.org"
    "https://nix-darwin.cachix.org"
    "https://nix-community.cachix.org"
    "https://install.determinate.systems"
  ];

  # Public keys for the substituters above. (cache.nixos.org's key is included by default.)
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-darwin.cachix.org-1:LxMyKzQk7Uqkc1Pfq5uhm9GSn07xkERpy+7cpwc006A="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM"
  ];

  trusted-users = [
    "root"
    "@wheel" # Users in `wheel` group
    "@admin" # Users in `admin` group (mainly MacOS)
  ];
in
{
  imports = [ inputs.determinate.darwinModules.default ];

  nix.enable = false; # Let Determinate Nix handle the Nix configuration.

  determinateNix = {
    enable = true;

    customSettings = {
      # Enables parallel evaluation (remove this setting or set the value to 1 to disable)
      eval-cores = 0;

      # Disable global registry
      flake-registry = "";

      # Allow us to use x86_64-darwin macos binaries on aarch64-darwin systems
      extra-platforms = lib.mkIf (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") [
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      lazy-trees = true;
      warn-dirty = false;

      experimental-features = [
        "nix-command"
        "flakes"
      ];

      extra-experimental-features = [
        "build-time-fetch-tree" # Enables build-time flake inputs
        "parallel-eval" # Enables parallel evaluation
      ];

      substituters = substituters;
      trusted-public-keys = trusted-public-keys;
      trusted-users = trusted-users;
      builders-use-substitutes = true;
    };
  };
}
