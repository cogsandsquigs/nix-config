{ inputs, config, ... }: {
    flake.modules.nixos.fixes = { };

    flake.modules.darwin.fixes = {
        # activationScripts are executed every time you boot the system or run `darwin-rebuild`.
        system.activationScripts = {
            postActivation.text = ''
                # activateSettings -u will reload the settings from the database and apply them
                # to the current session, so we do not need to logout and login again to make
                # the changes take effect. We do `sudo -u ${config.me.username}` to run the command
                # as the user.
                sudo -u ${config.me.username} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
            '';
        };

        # Fix for MacOS apps not appearing on spotlight-search. Need to copy the desktop apps
        # because otherwise spotlight does not find them.
        #
        # See: https://gist.github.com/Jabb0/1b7ad92e8ab3065ac999c21edc23311f
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
    };

}
