# Ghostty terminal (Home Manager module).
{
    flake.modules.homeManager."apps/ghostty" =
        { pkgs, lib, ... }:
        let
            inherit (pkgs.stdenv) hostPlatform;

            # `ghostty` pkg is linux only, `ghostty-bin` is macos only (binary release).
            package = if hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

            # GTK resolves a point at 96 dpi and macOS at 72, so one number renders 4/3 larger on
            # Linux.
            fontSize = if hostPlatform.isDarwin then 13 else 10;
        in
        {
            home.packages = [ package.terminfo ];

            programs.ghostty = {
                enable = true;
                inherit package;

                clearDefaultKeybinds = false;

                enableBashIntegration = true;
                enableZshIntegration = true;
                enableFishIntegration = true;

                settings = {
                    font-family = [
                        "FiraCode Nerd Font Mono"
                        "DejaVu Sans Mono"
                        "Twitter Color Emoji"
                    ];
                    font-size = fontSize;

                    font-feature = [
                        "+calt"
                        "+liga"
                        "+ss02"
                        "+ss09"
                        "+ss07"
                    ];

                    adjust-cell-width = 0;
                    adjust-cell-height = 0;
                    font-thicken = false;

                    theme = "Catppuccin Mocha";
                    cursor-style = "bar";

                    confirm-close-surface = false;
                    quit-after-last-window-closed = true;

                    window-colorspace = "display-p3"; # macOS only
                    window-padding-balance = true;

                    shell-integration-features = [
                        "cursor"
                        "sudo"
                        "title"
                        "ssh-terminfo"
                        "ssh-env"
                    ];

                    ## MACOS SPECIFIC OPTIONS ##
                    macos-titlebar-style = "transparent";
                    macos-non-native-fullscreen = "padded-notch";
                }
                // lib.optionalAttrs hostPlatform.isLinux { mouse-scroll-multiplier = "discrete:0.5"; };
            };
        };
}
