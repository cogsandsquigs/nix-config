# Mostly taken from https://github.com/ryan4yin/nix-darwin-kickstarter/blob/main/minimal/flake.nix
{
    description = ''
        My personal NixOS/Nix-Darwin configuration for my daily driver devices.
    '';

    inputs = {
        # Main packages repo
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Unstable

        # MacOS config
        nix-darwin = {
            url = "github:nix-darwin/nix-darwin/master"; # Unstable
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # Home Manager
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs =
        inputs@{
            self,
            nix-darwin,
            nixpkgs,
            home-manager,
        }:
        let
            inherit (self) outputs;

            mkDarwinConfiguration =
                hostname: username:
                nix-darwin.lib.darwinSystem {
                    system = "aarch64-darwin";

                    # NOTE: Doing this allows us to import `specialArgs` in
                    # `{specialArgs, ...}: <...>`, which lets us get certain information we need
                    specialArgs = {
                        inherit
                            inputs
                            outputs
                            hostname
                            username
                            ;
                    };

                    modules = [
                        ./system/all # Global config
                        ./system/darwin # MacOS-specific config

                        home-manager.darwinModules.home-manager
                        {
                            home-manager.useUserPackages = true;
                            home-manager.backupFileExtension = "backup"; # Backup files when moving to home-manager config
                            home-manager.extraSpecialArgs = {
                                inherit
                                    inputs
                                    outputs
                                    hostname
                                    username
                                    ;
                            };

                            home-manager.users.${username} =
                                { ... }:
                                {
                                    # Essentially, we create a module here that just imports the
                                    # home-manager configuration for the user.
                                    imports = [
                                        ./home/all
                                        ./home/darwin
                                    ];
                                };

                            # Fix to allow desktop apps to link in place where spotlight can find them
                            # Need to copy the desktop apps because otherwise spotlight does not find them.
                            # https://gist.github.com/Jabb0/1b7ad92e8ab3065ac999c21edc23311f
                            home-manager.sharedModules = [
                                {
                                    home.activation = {
                                        copyNixApps = inputs.home-manager.lib.hm.dag.entryAfter [ "linkGeneration" ] ''
                                            # Create directory for the applications
                                            mkdir -p "$HOME/Applications/Nix Apps"
                                            # Remove old entries
                                            rm -rf "$HOME/Applications/Nix Apps"/*
                                            # Get the target of the symlink from home-manager
                                            NIXAPPS="$newGenPath/home-path/Applications"
                                            # For each application
                                            for app_link in "$NIXAPPS"/*; do
                                              if [ -d "$app_link" ] || [ -L "$app_link" ]; then
                                                  # Resolve the symlink to get the actual app in the nix store
                                                  app_source=$(readlink -f "$app_link")
                                                  appname=$(basename "$app_source")
                                                  target="$HOME/Applications/Nix Apps/$appname"
                                                  
                                                  # Create the basic structure
                                                  mkdir -p "$target"
                                                  mkdir -p "$target/Contents"
                                                  
                                                  # Copy the Info.plist file
                                                  if [ -f "$app_source/Contents/Info.plist" ]; then
                                                    mkdir -p "$target/Contents"
                                                    cp -f "$app_source/Contents/Info.plist" "$target/Contents/"
                                                  fi
                                                  
                                                  # Copy icon files
                                                  if [ -d "$app_source/Contents/Resources" ]; then
                                                    mkdir -p "$target/Contents/Resources"
                                                    find "$app_source/Contents/Resources" -name "*.icns" -exec cp -f {} "$target/Contents/Resources/" \;
                                                  fi
                                                  
                                                  # Symlink the MacOS directory (contains the actual binary)
                                                  if [ -d "$app_source/Contents/MacOS" ]; then
                                                    ln -sfn "$app_source/Contents/MacOS" "$target/Contents/MacOS"
                                                  fi
                                                  
                                                  # Symlink other directories
                                                  for dir in "$app_source/Contents"/*; do
                                                    dirname=$(basename "$dir")
                                                    if [ "$dirname" != "Info.plist" ] && [ "$dirname" != "Resources" ] && [ "$dirname" != "MacOS" ]; then
                                                      ln -sfn "$dir" "$target/Contents/$dirname"
                                                    fi
                                                  done
                                                fi
                                                done
                                        '';
                                    };
                                }
                            ];
                        }
                    ];
                };
        in
        {
            # Build darwin flake using:
            # $ darwin-rebuild build --flake .#${hostname}
            darwinConfigurations."Ians-GlorpBook-Pro" = mkDarwinConfiguration "Ians-GlorpBook-Pro" "cogs";
        };
}
