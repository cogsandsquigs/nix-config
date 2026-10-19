{
    flake.modules.homeManager."apps/git" =
        {
            pkgs,
            lib,
            osConfig,
            ...
        }:
        let
            catppuccinDeltaTheme = pkgs.fetchFromGitHub {
                owner = "catppuccin";
                repo = "delta";
                rev = "011516f5d14f66b771b3e716f29c77231e008c74";
                hash = "sha256-lztkxX9O41YossvRzpR7tqxMhDNT1Efy2JvkCwtsiXQ=";
            };

            # Decrypted by the system-level sops-nix module (see the host config).
            signingKeyFile = osConfig.sops.secrets."gpg-key".path;
        in
        {
            home.activation.importGpgSigningKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                if [ -r "${signingKeyFile}" ]; then
                    $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import "${signingKeyFile}" || true
                    $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpgconf --kill gpg-agent || true
                fi
            '';

            programs = {
                git = {
                    enable = true;
                    package = pkgs.gitFull;

                    settings = {
                        include.path = "${catppuccinDeltaTheme}/catppuccin.gitconfig";

                        user = {
                            name = "Ian Pratt";
                            email = "ianjdpratt@gmail.com";
                        };

                        url."ssh://git@gitlab.doc.ic.ac.uk/".insteadOf = "https://gitlab.doc.ic.ac.uk/";

                        core.autocrlf = "input";
                        init.defaultBranch = "main";
                        pull.rebase = false;
                        merge.conflictStyle = "zdiff3";

                        credential.helper =
                            if pkgs.stdenv.hostPlatform.isDarwin then
                                "osxkeychain"
                            else
                                "${pkgs.gitFull}/bin/git-credential-libsecret";

                        gpg.program = "${pkgs.gnupg}/bin/gpg";
                    };

                    signing = {
                        key = "E0DB58169CA551AA!";
                        signByDefault = true;
                    };
                };

                delta = {
                    enable = true;
                    enableGitIntegration = true;

                    options = {
                        diff-highlight = true;
                        features = "catppuccin-mocha";
                        zero-style = "syntax";
                        relative-paths = true;
                        file-style = "omit";
                        hunk-header-style = "file line-number syntax";
                        hunk-header-decoration-style = "blue ul";
                    };
                };

                lazygit = {
                    enable = true;
                    enableBashIntegration = true;
                    enableZshIntegration = true;
                    enableFishIntegration = true;
                    settings.git.diffRenderers = [ { command = "delta --dark --paging=never"; } ];
                };
            };
        };
}
