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
    inherit (self) outputs;

    mkDarwinConfiguration = hostname: username:
      nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs outputs hostname;
          # userConfig = users.${username};
        };
        modules = [
          ./home.nix
          home-manager.darwinModules.home-manager
        ];
      };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#${hostname}
    darwinConfigurations."Ians-GlorpBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [
        ./modules # Global config
        ./modules/darwin # MacOS-specific config

        # Home-manager (darwin, i think?)
        inputs.home-manager.darwinModules.home-manager
        {
          nixpkgs = {
            config.allowUnfree = true;
          };
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup"; # Backup files when moving to home-manager config
          home-manager.users."cogs" = import ./home/home.nix;
        }
      ];
    };
  };
}
