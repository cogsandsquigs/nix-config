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
    # Identity/signing are the only per-user-varying bits, so they get value options (a user unit
    # overrides just these — e.g. a work email, signing off until a work key is imported). The rest
    # of the git config below is identical everywhere, so it stays inline.
    options.my.user.git = {
        enable = tools.mkEnabled "git + delta + lazygit (identity/signing via my.user.git.*)";
        userName = tools.mkStr "Ian Pratt" "Value for git user.name.";
        email = tools.mkStr "ianjdpratt@gmail.com" "Value for git user.email.";
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
        # Secret path-hole (agnostic — see lib/opts.nix). When a unit wires a decrypted GPG secret
        # key here, it's imported into the keyring at activation. null = don't import (the key is
        # already present, e.g. on the machine where it was created). Wiring: see secrets/README.md.
        signingKeyFile = tools.mkSecretPath "Path to a decrypted exported GPG secret key to import at activation.";
    };

    config = lib.mkIf cfg.enable {
        home.packages = with pkgs; [
            git # <3
            delta # Git diff highlighting
            lazygit # Awesome git TUI
        ];

        # Import the signing key into the user's GnuPG keyring at activation, if a unit wired one
        # via `signingKeyFile` (e.g. an agenix-decrypted secret). Idempotent — `gpg --import` skips
        # keys already present, so it's a no-op on the machine that already has the key. mkIf keeps
        # this absent (no activation entry) when no key is wired.
        home.activation.importGpgSigningKey = lib.mkIf (cfg.signingKeyFile != null) (
            lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                if [ -r "${cfg.signingKeyFile}" ]; then
                    $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import "${cfg.signingKeyFile}" || true
                fi
            ''
        );

        programs.git = {
            enable = true;

            settings = {
                # Basic user settings. Values come from the `my.user.git.*` options declared above, so
                # a user unit can override the identity without editing this file — e.g. a work email.
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
                init.defaultBranch = "main"; # Default new branch is `main`
                pull.rebase = false; # Pull behavior: setting rebase to false

                # Credential helper. On macOS use the native keychain. On Linux use libsecret
                # (talks to the running Secret Service — gnome-keyring / KWallet), NOT the plaintext
                # `store` helper. The libsecret helper ships inside the git package on Linux;
                # git's old `gnome-keyring` helper is deprecated in favour of it.
                credential.helper =
                    if pkgs.stdenv.isDarwin then "osxkeychain" else "${pkgs.git}/bin/git-credential-libsecret";

                # For some reason `signing.signer` doesn't set the GPG program, so I gotta do this
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
