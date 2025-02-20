# Mostly taken from https://github.com/ryan4yin/nix-darwin-kickstarter/blob/main/minimal/flake.nix
{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # MacOS config
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    home-manager,
  }: let
    # TODO replace with your own username, system and hostname
    username = "ianpratt";
    platform = "aarch64-darwin"; # aarch64-darwin or x86_64-darwin
    hostname = "Ians-GlorpBook-Pro";

    specialArgs =
      inputs
      // {
        inherit username hostname;
      };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#${hostname}
    darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
      modules = [
        ./modules # Global config
        ./modules/darwin # MacOS-specific config
      ];
    };
  };
}
