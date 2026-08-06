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
            cfg = config.my.user.cli.git;

            catppuccinDeltaTheme = pkgs.fetchFromGitHub {
                owner = "catppuccin";
                repo = "delta";
                rev = "011516f5d14f66b771b3e716f29c77231e008c74";
                hash = "sha256-lztkxX9O41YossvRzpR7tqxMhDNT1Efy2JvkCwtsiXQ=";
            };
        in
        {
            options.my.user.cli.git = {
                enable = tools.opt.mkEnabled "git + delta + lazygit (identity/signing via my.user.cli.git.*)";
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
                # No `home.packages`: the three `programs.*` blocks below install gitFull, delta and
                # lazygit themselves.

                # gpg --import is idempotent; kill the agent after so it picks up the new keygrip immediately
                # (gpg-agent caches state and won't reflect the import until restarted).
                home.activation.importGpgSigningKey = lib.mkIf (cfg.signingKeyFile != null) (
                    lib.hm.dag.entryAfter [ "writeBoundary" "sops-nix" ] ''
                        if [ -r "${cfg.signingKeyFile}" ]; then
                            $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import "${cfg.signingKeyFile}" || true
                            $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpgconf --kill gpg-agent || true
                        fi
                    ''
                );

                programs.git = {
                    enable = true;
                    package = pkgs.gitFull;

                    settings = {
                        include = {
                            path = "${catppuccinDeltaTheme}/catppuccin.gitconfig";
                        };

                        user = {
                            name = cfg.userName;
                            inherit (cfg) email;
                        };

                        url = {
                            "ssh://git@gitlab.doc.ic.ac.uk/" = {
                                insteadOf = "https://gitlab.doc.ic.ac.uk/";
                            };
                        };

                        core.autocrlf = "input";
                        init.defaultBranch = "main";
                        pull.rebase = false;
                        merge.conflictStyle = "zdiff3";

                        # libsecret ships inside the git package on Linux (not a separate package).
                        credential.helper =
                            if pkgs.stdenv.isDarwin then "osxkeychain" else "${pkgs.gitFull}/bin/git-credential-libsecret";

                        # signing.signer doesn't wire gpg.program -- set it here.
                        gpg.program = "${pkgs.gnupg}/bin/gpg";

                    };

                    signing = {
                        key = cfg.signingKey;
                        inherit (cfg) signByDefault;
                        # signer = "${pkgs.gnupg}/bin/gpg"; # NOTE: See `extraConfig.gpg.program`
                    };
                };

                # Diff highlighting
                programs.delta = {
                    enable = true;
                    enableGitIntegration = true;

                    options = {
                        diff-highlight = true;
                        features = "catppuccin-mocha";
                    };
                };

                # Git TUI
                programs.lazygit = {
                    enable = true;

                    enableBashIntegration = true;
                    enableZshIntegration = true;
                    enableFishIntegration = true;

                    settings = {
                        git.diffRenderers = [ { command = "delta --dark --paging=never"; } ];
                    };
                };
            };
        };
}
