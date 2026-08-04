# Ghostty terminal. (zellij lives in ./utils, which is imported alongside this module.)
{
    home =
        {
            pkgs,
            lib,
            config,
            inputs,
            tools,
            ...
        }:
        let
            cfg = config.my.user.cli.terminal;
        in
        {
            options.my.user.cli.terminal = {
                enable = tools.opt.mkEnabled "ghostty terminal";
                nixGL.enable = tools.opt.mkDisabled ''
                    Whether to run ghostty through nixGL. Needed on a non-NixOS Linux host, where the
                    store-built ghostty cannot see the distro's OpenGL driver. Assumes a Mesa GPU
                    (`nixGL.defaultWrapper`); an Nvidia one also needs `--impure`.
                '';

                localInstall.enable = tools.opt.mkDisabled ''
                    Whether ghostty comes from the host's own package manager, leaving only its config
                    managed here. The escape hatch for a desktop the store build cannot satisfy: a
                    GTK >= 4.16 client hands cursor sizing to the compositor, and mutter 46 on Ubuntu
                    24.04 answers with an oversized pointer for every such client.
                '';

                # Per-platform because the units differ, not because taste does: GTK resolves a point
                # at 96 dpi and macOS at 72, so one number renders 4/3 larger on Linux. Overridable
                # per host, since the display scale multiplies on top of it.
                fontSize = lib.mkOption {
                    type = lib.types.numbers.positive;
                    default = if pkgs.stdenv.isDarwin then 13 else 10;
                    defaultText = lib.literalMD "`13` on darwin, `10` on Linux";
                    description = "ghostty font size in points (non-integer allowed).";
                };
            };

            config =
                let
                    # For some reason `ghostty` pkg is linux only, but `ghostty-bin` is macos-only
                    # (binary release)
                    base = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

                    # The wrapper preserves every output and repoints the .desktop files, so shell
                    # integration and the app entry still resolve.
                    ghostty-pkg = if cfg.nixGL.enable then config.lib.nixGL.wrap base else base;
                in
                lib.mkIf cfg.enable {
                    # ghostty resolves `font-family` at runtime, so a missing FiraCode falls back
                    # silently rather than failing the build.
                    assertions = [
                        {
                            assertion = config.my.user.fonts.enable;
                            message = "my.user.cli.terminal.enable requires my.user.fonts.enable (FiraCode Nerd Font Mono)";
                        }
                        {
                            assertion = !(cfg.localInstall.enable && cfg.nixGL.enable);
                            message = "my.user.cli.terminal.nixGL.enable wraps the nixpkgs ghostty, which localInstall.enable does not install";
                        }
                    ];

                    # Empty by default, which makes `lib.nixGL.wrap` the identity function, so the
                    # wrapper set is fetched only where the option is on.
                    targets.genericLinux.nixGL.packages = lib.mkIf cfg.nixGL.enable inputs.nixGL.packages;

                    home.packages = lib.optionals (!cfg.localInstall.enable) [ ghostty-pkg ];

                    programs.ghostty = {
                        enable = true;
                        package = if cfg.localInstall.enable then null else ghostty-pkg;

                        # The unit's ExecStart is a store path, so there is nothing to point it at.
                        # mkIf rather than a plain bool, to leave the platform default alone otherwise.
                        systemd.enable = lib.mkIf cfg.localInstall.enable false;

                        clearDefaultKeybinds = false;

                        enableBashIntegration = true;
                        enableZshIntegration = true;
                        enableFishIntegration = true;

                        settings = {
                            # Named fallback, repeated in order. Without one, every glyph FiraCode
                            # lacks resolves independently -- Claude Code's six spinner frames landed
                            # in four different faces, so the animation jittered. Emoji are exempt:
                            # ghostty always routes those to the platform emoji font.
                            font-family = [
                                "FiraCode Nerd Font Mono"
                                "DejaVu Sans Mono"
                            ];
                            font-size = cfg.fontSize;

                            # Applies to every weight: ghostty has no per-weight scoping.
                            font-feature = [
                                "+calt"
                                "+liga" # More ligatures
                                "+ss02"
                                "+ss09"
                                "+ss07"
                            ];

                            # Corrects cell spacing without altering the global font scale
                            adjust-cell-width = 0;
                            adjust-cell-height = 0;

                            # Prevents the glyph atlas from altering cell sizing dynamically
                            font-thicken = false;

                            theme = "Catppuccin Mocha";

                            cursor-style = "bar";

                            # Close a surface even mid-process: zellij owns the session, so asking
                            # is pointless.
                            confirm-close-surface = false;

                            quit-after-last-window-closed = true;

                            window-colorspace = "display-p3"; # macOS only
                            window-padding-balance = true; # Buffer top of window a little bit.
                        }
                        // lib.optionalAttrs pkgs.stdenv.isLinux {
                            # ghostty's GTK path counts every high-resolution wheel event as a full
                            # click, so a free-spinning wheel scrolls ~10 notches at once in any
                            # mouse-reporting app (helix, less, lazygit). Upstream bug, no fix in 1.3.1.
                            mouse-scroll-multiplier = "discrete:0.3";
                        };
                    };
                };
        };
}
