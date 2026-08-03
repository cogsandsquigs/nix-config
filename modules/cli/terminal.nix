# Ghostty terminal. (zellij lives in ./utils, which is imported alongside this module.)
{
    home =
        {
            pkgs,
            lib,
            config,
            tools,
            ...
        }:
        {
            options.my.user.cli.terminal.enable = tools.opt.mkEnabled "ghostty terminal";

            config =
                let
                    # For some reason `ghostty` pkg is linux only, but `ghostty-bin` is macos-only
                    # (binary release)
                    ghostty-pkg = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
                in
                lib.mkIf config.my.user.cli.terminal.enable {
                    # ghostty resolves `font-family` at runtime, so a missing FiraCode falls back
                    # silently rather than failing the build.
                    assertions = [
                        {
                            assertion = config.my.user.fonts.enable;
                            message = "my.user.cli.terminal.enable requires my.user.fonts.enable (FiraCode Nerd Font Mono)";
                        }
                    ];

                    home.packages = [
                        ghostty-pkg
                        pkgs.ncurses # GhosTTY XTerm info
                    ];

                    programs.ghostty = {
                        enable = true;
                        package = ghostty-pkg;

                        clearDefaultKeybinds = false;

                        enableBashIntegration = true;
                        enableZshIntegration = true;
                        enableFishIntegration = true;

                        settings = {
                            font-family = "FiraCode Nerd Font Mono";
                            font-size = 13;

                            # Applies to every weight: ghostty has no per-weight scoping.
                            font-feature = [
                                "+ss02"
                                "+ss09"
                                "+ss07"
                            ];

                            theme = "Catppuccin Mocha";

                            cursor-style = "bar";

                            # Close a surface even mid-process: zellij owns the session, so asking is
                            # pointless.
                            confirm-close-surface = false;

                            quit-after-last-window-closed = true;

                            window-colorspace = "display-p3"; # macOS only
                        };
                    };
                };
        };
}
