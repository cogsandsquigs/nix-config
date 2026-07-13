# Nix daemon settings for NixOS (darwin uses Determinate Nix instead — see system/darwin/nix.nix).
{ inputs, ... }:
let
    substituters = [
        "https://cache.nixos.org"
        "https://nix-darwin.cachix.org"
        "https://nix-community.cachix.org"
        "https://install.determinate.systems"
    ];

    trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-darwin.cachix.org-1:LxMyKzQk7Uqkc1Pfq5uhm9GSn07xkERpy+7cpwc006A="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM"
    ];

    trusted-users = [
        "root"
        "@wheel"
        "@admin"
    ];
in
{
    nix = {
        enable = true;
        registry.nixpkgs.flake = inputs.nixpkgs;
        settings = {
            experimental-features = [
                "nix-command"
                "flakes"
            ];

            substituters = substituters;
            trusted-public-keys = trusted-public-keys;
            trusted-users = trusted-users;
            builders-use-substitutes = true;
        };

        # Collect garbage. See: https://wiki.nixos.org/wiki/Storage_optimization#Garbage_collection
        gc = {
            automatic = true;
            options = "--delete-older-than 30d";
            dates = "weekly";
        };

        # Optimise the store on a schedule.
        # See: https://wiki.nixos.org/wiki/Storage_optimization#Optimising_the_store
        optimise = {
            automatic = true;
            dates = "weekly";
        };

        extraOptions = ''
            warn-dirty = false
            keep-outputs = true
        '';
    };
}
