{
    home =
        {
            pkgs,
            lib,
            config,
            tools,
            ...
        }:
        let
            inherit (pkgs) stdenv;
            inherit (lib) mkIf optionalAttrs;

            # `UseKeychain` is an Apple-only addition to OpenSSH. Stock OpenSSH (i.e. Ubuntu, NixOS)
            # rejects it as an unknown keyword and refuses to parse the whole config, so it must only
            # ever be emitted on Darwin.
            keychain = optionalAttrs stdenv.hostPlatform.isDarwin {
                IgnoreUnknown = "UseKeychain";
                UseKeychain = "yes";
            };
        in
        {
            options.my.user.cli.ssh = {
                # Enables SSH config and such.
                enable = tools.opt.mkEnabled "ssh client config";

                # # SSH IP aliases
                # aliases = tools.opt.mk
            };

            config = mkIf config.my.user.cli.ssh.enable {
                programs.ssh = {
                    enable = true;
                    enableDefaultConfig = false;

                    includes = [
                        # Required for Colima to work properly
                        (mkIf stdenv.hostPlatform.isDarwin "~/.colima/ssh_config")
                    ];

                    # Per-host settings rules. Only what differs from stock OpenSSH: `enableDefaultConfig
                    # = false` means home-manager writes no `Host *` block of its own, so ssh's own
                    # defaults stand and restating them here would be nine no-op lines.
                    settings = {
                        "*" = {
                            # NOT a default -- Ubuntu's /etc/ssh/ssh_config sets `HashKnownHosts yes`, and
                            # ~/.ssh/config is read first, so this is what overrides it.
                            HashKnownHosts = false;

                            # Tried in order, and a per-host block below prepends to this list rather
                            # than replacing it -- so a host only needs an entry when its key is not the
                            # first one here.
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
                            # SetEnv = {
                            #     TERM = "xterm-256color";
                            # };
                        };
                    };
                };
            };
        };
}
