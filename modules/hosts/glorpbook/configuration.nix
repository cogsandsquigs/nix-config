{
    self,
    inputs,
    config,
    ...
}:
{
    flake.darwinConfigurations.glorpbook = inputs.nix-darwin.lib.darwinSystem {
        modules = [ self.modules.darwin."hosts/glorpbook" ];
        specialArgs = { inherit inputs; };
    };

    flake.modules.darwin."hosts/glorpbook" = {
        imports = [
            self.modules.darwin.base
            self.modules.darwin.secrets
            self.modules.darwin.games # All my gaming stuffs.
            self.modules.darwin.services
            self.modules.darwin."sessions/macos"
        ];

        system.stateVersion = 6;
        system.primaryUser = config.me.username; # TODO: set to your real macOS username
        nixpkgs.hostPlatform = "aarch64-darwin";

        users.users.${config.me.username}.home = "/Users/${config.me.username}"; # Required by the home-manager darwin module.

        home-manager.users.${config.me.username} = {
            home.stateVersion = "25.05";
            imports = [
                self.modules.homeManager.apps # All my applications
                self.modules.homeManager.develop # Developer stuff
            ];
        };

        # Secrets configuration
        sops = {
            # Don't mix sshKeyPaths and keyFile. This is a path ON THE MACHINE, not in the repo:
            # install the private key there once, by hand:
            #   sudo install -m600 -D <key> /var/lib/sops-nix/key.txt
            age.sshKeyPaths = [ ];
            age.keyFile = "/etc/nix/age/glorpbook.age";

            secrets = {
                "gpg-key" = {
                    sopsFile = ../../secrets/values/glorpbook/gpg-key.yaml;
                    # Read by the user's home-manager activation (apps/git.nix), so it must be
                    # owned by the user (and thus can't be `neededForUsers`).
                    owner = config.me.username;
                    mode = "0400";
                };
            };
        };
    };
}
