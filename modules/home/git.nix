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
    options.my.user.git.enable =
        tools.mkEnabled "git + delta + lazygit (identity/signing via my.user.git.*)";

    config = lib.mkIf cfg.enable {
        home.packages = with pkgs; [
            git # <3
            delta # Git diff highlighting
            lazygit # Awesome git TUI
        ];

        programs.git = {
            enable = true;

            settings = {
                # Basic user settings. Values come from `my.user.git.*` (see modules/home/options.nix)
                # so a user unit can override the identity without editing this file — e.g. the work
                # user uses a work email.
                user = {
                    name = config.my.user.git.userName;
                    email = config.my.user.git.email;
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
                key = config.my.user.git.signingKey;
                signByDefault = config.my.user.git.signByDefault;
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
