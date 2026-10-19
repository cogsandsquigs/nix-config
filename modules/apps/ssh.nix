{
    flake.modules.homeManager."apps/ssh" =
        { pkgs, lib, ... }:
        let
            inherit (pkgs) stdenv;

            # `UseKeychain` is Apple-only; stock OpenSSH rejects it. Darwin only.
            keychain = lib.optionalAttrs stdenv.hostPlatform.isDarwin {
                IgnoreUnknown = "UseKeychain";
                UseKeychain = "yes";
            };
        in
        {
            programs.ssh = {
                enable = true;
                enableDefaultConfig = false;

                # Colima needs its generated ssh_config.
                includes = lib.optional stdenv.hostPlatform.isDarwin "~/.colima/ssh_config";

                settings = {
                    "*" = {
                        HashKnownHosts = false;
                        IdentityFile = [
                            "~/.ssh/id_ed25519"
                            "~/.ssh/homeserver_rsa"
                            "~/.ssh/imperial_doc_ed25519"
                            "~/.ssh/imperial_gitlab_ed25519"
                        ];
                        AddKeysToAgent = "yes";
                    }
                    // keychain;

                    "*.doc.ic.ac.uk" = {
                        User = "ip124";
                        IdentityFile = "~/.ssh/imperial_doc_ed25519";
                    };

                    "gitlab.doc.ic.ac.uk" = {
                        IdentityFile = "~/.ssh/imperial_gitlab_ed25519";
                    };

                    ## WORK MACHINE ##
                    "workbox" = {
                        User = "ipratt";
                        HostName = "172.24.20.25";
                    };
                };
            };
        };
}
