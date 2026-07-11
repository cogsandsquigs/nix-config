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
    keychain = optionalAttrs stdenv.isDarwin { UseKeychain = "yes"; };
in
{
    options.my.user.ssh.enable = tools.opt.mkEnabled "ssh client config";

    config = mkIf config.my.user.ssh.enable {
        programs.ssh = {
            enable = true;
            enableDefaultConfig = false;

            includes = [
                # Required for Colima to work properly
                (mkIf stdenv.isDarwin "~/.colima/ssh_config")
            ];

            # Per-host settings rules
            settings = {
                # Default values!
                # See: https://home-manager-options.extranix.com/?query=programs.ssh&release=master
                "*" = {
                    ForwardAgent = false;
                    Compression = false;
                    ServerAliveInterval = 0;
                    ServerAliveCountMax = 3;
                    HashKnownHosts = false;
                    UserKnownHostsFile = "~/.ssh/known_hosts";
                    ControlMaster = "no";
                    ControlPath = "~/.ssh/master-%r@%n:%p";
                    ControlPersist = "no";

                    IdentityFile = [
                        "~/.ssh/id_ed25519"
                        "~/.ssh/homeserver_rsa"
                        "~/.ssh/homeserver_rsa"
                        "~/.ssh/imperial_gitlab_ed25519"
                    ];
                    AddKeysToAgent = "yes";
                }
                // keychain;

                "*.doc.ic.ac.uk" = {
                    User = "ip124";
                    IdentityFile = "~/.ssh/imperial_doc_ed25519";
                    AddKeysToAgent = "yes";
                }
                // keychain;

                "gitlab.doc.ic.ac.uk" = {
                    IdentityFile = "~/.ssh/imperial_gitlab_ed25519";
                    AddKeysToAgent = "yes";
                }
                // keychain;

                "github.com" = {
                    IdentityFile = "~/.ssh/id_ed25519";
                    AddKeysToAgent = "yes";
                }
                // keychain;
            };
        };
    };
}
