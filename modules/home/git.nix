{
    pkgs,
    lib,
    config,
    tools,
    ...
}:
let
    cfg = config.my.user.git;
in
{
    options.my.user.git = {
        enable = tools.opt.mkEnabled "git + delta + lazygit (identity/signing via my.user.git.*)";
        userName = tools.opt.mkStr "Ian Pratt" "Value for git user.name.";
        email = tools.opt.mkStr "ianjdpratt@gmail.com" "Value for git user.email.";
        signingKey = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = "E0DB58169CA551AA!";
            description = "GPG signing key id (null to leave unset).";
        };
        signByDefault = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to GPG-sign every commit by default.";
        };
        # Decrypted GPG key to import at activation; null = key already in keyring. See secrets/README.md.
        signingKeyFile = tools.opt.mkSecretPath "Path to a decrypted exported GPG secret key to import at activation.";
    };

    config = lib.mkIf cfg.enable {
        home.packages = with pkgs; [
            git # <3
            delta # Git diff highlighting
            lazygit # Awesome git TUI
        ];

        # gpg --import is idempotent; kill the agent after so it picks up the new keygrip immediately
        # (gpg-agent caches state and won't reflect the import until restarted).
        home.activation.importGpgSigningKey = lib.mkIf (cfg.signingKeyFile != null) (
            lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                if [ -r "${cfg.signingKeyFile}" ]; then
                    $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import "${cfg.signingKeyFile}" || true
                    $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpgconf --kill gpg-agent || true
                fi
            ''
        );

        programs.git = {
            enable = true;

            settings = {
                user = {
                    name = cfg.userName;
                    email = cfg.email;
                };

                url = {
                    "ssh://git@gitlab.doc.ic.ac.uk/" = {
                        insteadOf = "https://gitlab.doc.ic.ac.uk/";
                    };
                };

                core.autocrlf = "input";
                init.defaultBranch = "main";
                pull.rebase = false;

                # libsecret ships inside the git package on Linux (not a separate package).
                credential.helper =
                    if pkgs.stdenv.isDarwin then "osxkeychain" else "${pkgs.git}/bin/git-credential-libsecret";

                # signing.signer doesn't wire gpg.program — set it here.
                gpg.program = "${pkgs.gnupg}/bin/gpg";
            };

            signing = {
                key = cfg.signingKey;
                signByDefault = cfg.signByDefault;
                # signer = "${pkgs.gnupg}/bin/gpg"; # NOTE: See `extraConfig.gpg.program`
            };
        };

        # Diff highlighting
        programs.delta = {
            enable = true;
            enableGitIntegration = true;

            options = {
                diff-highlight = true;
            };
        };
    };
}
