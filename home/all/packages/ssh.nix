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

        extraConfig = ''
            IdentityFile ~/.ssh/id_ed25519
            IdentityFile ~/.ssh/homeserver_rsa
            IdentityFile ~/.ssh/imperial_doc_ed25519
        '';

        # Per-host matching rules
        matchBlocks = {
            "*" = {
                identityFile = "~/.ssh/id_ed25519";
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
