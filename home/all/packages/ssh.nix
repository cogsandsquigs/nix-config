{ pkgs, lib, ... }:
let
    inherit (pkgs) stdenv;
    inherit (lib) mkIf;
in
{
    programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        includes = [
            # Required for Colima to work properly
            (mkIf stdenv.isDarwin "~/.colima/ssh_config")
        ];

        # Per-host matching rules
        matchBlocks = {
            # Default values!
            # See: https://home-manager-options.extranix.com/?query=programs.ssh&release=master
            "*" = {
                forwardAgent = false;
                addKeysToAgent = "no";
                compression = false;
                serverAliveInterval = 0;
                serverAliveCountMax = 3;
                hashKnownHosts = false;
                userKnownHostsFile = "~/.ssh/known_hosts";
                controlMaster = "no";
                controlPath = "~/.ssh/master-%r@%n:%p";
                controlPersist = "no";
            };

            "*" = {
                identityFile = [
                    "~/.ssh/id_ed25519"
                    "~/.ssh/homeserver_rsa"
                    "~/.ssh/homeserver_rsa"
                    "~/.ssh/imperial_gitlab_ed25519"
                ];
                extraOptions = {
                    AddKeysToAgent = "yes";
                    UseKeychain = "yes";
                };
            };

            "*.doc.ic.ac.uk" = {
                user = "ip124";
                identityFile = "~/.ssh/imperial_doc_ed25519";
                extraOptions = {
                    AddKeysToAgent = "yes";
                    UseKeychain = "yes";
                };
            };

            "gitlab.doc.ic.ac.uk" = {
                identityFile = "~/.ssh/imperial_gitlab_ed25519";
                extraOptions = {
                    AddKeysToAgent = "yes";
                    UseKeychain = "yes";
                };
            };

            "github.com" = {
                identityFile = "~/.ssh/id_ed25519";
                extraOptions = {
                    AddKeysToAgent = "yes";
                    UseKeychain = "yes";
                };
            };
        };
    };
}
