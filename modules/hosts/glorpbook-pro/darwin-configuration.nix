{ ... }:
{

  flake.darwinConfigurations = {
    yavanna = :darwin-intel "yavanna";
    varda = darwin "varda";
    bert = darwin "bert";
  };

    flake.darwinModules.macbookConfiguration =
        { pkgs, lib, ... }:
        {
            imports = [
                # NOTE: No hardware configuration for this one, since uh. Its MacOS.
            ];

            nix.settings.experimental-features = [
                "nix-command"
                "flakes"
            ];

            environment.systemPackages = with pkgs; [
                firefox
                git
                helix
                vim
            ];

            nixpkgs = {
                hostPlatform = "aarch64-darwin";
                config.allowBroken = true;
            };

            system = {
                stateVersion = 6;

                # primaryUser = username; # The primary user of the system

                # # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
                # activationScripts = {
                #     postActivation.text = ''
                #         # activateSettings -u will reload the settings from the database and apply them to the current session,
                #         # so we do not need to logout and login again to make the changes take effect.
                #         # We do `sudo -u ${username}` to run the command as the user
                #         sudo -u ${username} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
                #     '';
                # };

                defaults = {
                    menuExtraClock.Show24Hour = false; # show 24 hour clock
                    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
                    loginwindow.GuestEnabled = false;
                    NSGlobalDomain.AppleInterfaceStyle = "Dark";

                    dock = {
                        autohide = true;
                        autohide-delay = 0.0;
                        autohide-time-modifier = 0.5;
                        persistent-apps = [
                            # "/System/Applications/Launchpad.app" # NOTE: Not recommended since MacOS 26!
                            "${pkgs.kitty}/Applications/kitty.app"
                            # "${pkgs.alacritty}/Applications/Alacritty.app"
                            "/System/Applications/System Settings.app"
                            # "${pkgs.firefox-unwrapped}/Applications/Firefox.app" # NOTE: See homebrew.nix for why it's `firefox-unwrapped`
                            "/Applications/Firefox.app" # NOTE: See homebrew.nix for why it's `firefox-unwrapped`
                            "${pkgs.obsidian}/Applications/Obsidian.app"
                            # "${pkgs.net-news-wire}/Applications/NetNewsWire.app"
                            "/Applications/Discord.app" # NOTE: See homebrew.nix
                            # "${pkgs.discord}/Applications/Discord.app"
                            # "${pkgs.spotify}/Applications/Spotify.app"
                            "/System/Applications/Messages.app"
                            "/Applications/WhatsApp.app" # "${pkgs.whatsapp-for-mac}/Applications/WhatsApp.app"
                            "/System/Applications/Calendar.app"

                            "/System/Applications/Reminders.app"
                            "/System/Applications/Photos.app"
                        ];
                    };

                };
            };

            # Add ability to used TouchID for sudo authentication
            security = {
                pam.services.sudo_local = {
                    enable = true;
                    touchIdAuth = true;
                };
            };
        };
}

/*
  outputs =
      inputs@{ flake-parts, import-tree, ... }:
      flake-parts.lib.mkFlake { inherit inputs; } (import-tree ./modules);

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
                          }
                      ];
                  };
          in
          {
              # Build darwin flake using:
              # $ darwin-rebuild build --flake .#${hostname}
              darwinConfigurations."Ians-GlorpBook-Pro" =
                  mkDarwinConfiguration "Ians-GlorpBook-Pro" "cogs";
          };
*/
