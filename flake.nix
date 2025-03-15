# Mostly taken from https://github.com/ryan4yin/nix-darwin-kickstarter/blob/main/minimal/flake.nix
{
  description = "Example nix-darwin system flake";

  inputs = {
    # Main packages repo
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Unstable
    # nixpkgs.url = "github:nixos/nixpkgs/release-24.11"; # Stable

    # MacOS config
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master"; # Unstable
      # url = "github:LnL7/nix-darwin/nix-darwin-24.11"; # Stable
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
    inherit (self) outputs;

    mkDarwinConfiguration = hostname: username:
      nix-darwin.lib.darwinSystem {
        # NOTE: Doing this allows us to import `specialArgs` in `{sspecialArgs, ...}: <...>`, which lets us
        # get certain information we need
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs outputs hostname username;
        };
        modules = [
          ./modules # Global config
          ./modules/darwin # MacOS-specific config

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup"; # Backup files when moving to home-manager config
            home-manager.users.${username} = import ./home/home.nix;
          }
        ];
      };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#${hostname}
    darwinConfigurations."Ians-GlorpBook-Pro" = mkDarwinConfiguration "Ians-GlorpBook-Pro" "cogs";
  };
}
