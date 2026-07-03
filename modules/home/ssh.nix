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
                UseKeychain = "yes";
            };

            "*.doc.ic.ac.uk" = {
                User = "ip124";
                IdentityFile = "~/.ssh/imperial_doc_ed25519";
                AddKeysToAgent = "yes";
                UseKeychain = "yes";
            };

            "gitlab.doc.ic.ac.uk" = {
                IdentityFile = "~/.ssh/imperial_gitlab_ed25519";
                AddKeysToAgent = "yes";
                UseKeychain = "yes";
            };

            "github.com" = {
                IdentityFile = "~/.ssh/id_ed25519";
                AddKeysToAgent = "yes";
                UseKeychain = "yes";
            };
        };
    };
}
