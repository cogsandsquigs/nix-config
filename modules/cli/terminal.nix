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

            config = lib.mkIf config.my.user.cli.terminal.enable {
                home.packages = with pkgs; [ ghostty ];

                programs.ghostty = {
                    enable = true;

                    clearDefaultKeybinds = false;

                    enableBashIntegration = true;
                    enableZshIntegration = true;
                    enableFishIntegration = true;

                    settings = {
                        font-family = "FiraCode Nerd Font Mono";
                        font-size = 13;

                        # Font features (global only — kitty's per-weight PostScript-name
                        # scoping has no ghostty equivalent, applies to all weights)
                        font-feature = [
                            "+ss02"
                            "+ss09"
                            "+ss07"
                        ];

                        theme = "catppuccin-mocha";

                        cursor-style = "bar"; # kitty beam -> ghostty bar

                        confirm-close-surface = false; # was confirm_os_window_close = 0

                        quit-after-last-window-closed = true; # macos_quit_when_last_window_closed

                        fullscreen = true; # darwinLaunchOptions "--start-as fullscreen"

                        window-colorspace = "display-p3"; # macos_colorspace, macOS only

                        # NOTE: no ghostty equivalent for kitty's `enabled_layouts`
                        # (tall/stack/etc) — ghostty uses native OS splits/tabs, not a
                        # kitty-style layout manager. Dropped.
                        # modify_font cell_width/height were +0px (no-op), omitted.
                        # Real keys if needed: adjust-cell-width / adjust-cell-height.

                        keybind = [
                            # Linux
                            "super+d=new_window"
                            "super+]=next_tab"
                            "super+[=previous_tab"

                            # macOS
                            "cmd+d=new_window"
                            "cmd+]=next_tab"
                            "cmd+[=previous_tab"
                        ];
                    };
                };
            };
        };
}

# # Kitty terminal. (zellij lives in ./utils, which is imported alongside this module.)
# {
#     home =
#         {
#             pkgs,
#             lib,
#             config,
#             tools,
#             ...
#         }:
#         {
#             options.my.user.cli.terminal.enable = tools.opt.mkEnabled "kitty terminal";

#             config = lib.mkIf config.my.user.cli.terminal.enable {
#                 home.packages = with pkgs; [ kitty ];

#                 programs.kitty = {
#                     enable = true;

#                     darwinLaunchOptions = [ "--start-as fullscreen" ];

#                     font = {
#                         name = "FiraCode Nerd Font Mono";
#                         package = pkgs.nerd-fonts.fira-code;
#                         size = 13;
#                     };

#                     keybindings = {
#                         # Linux keybinds
#                         "super+d" = "new_window";
#                         "super+]" = "next_window";
#                         "super+[" = "previous_window";

#                         # MacOS keybinds
#                         "cmd+d" = "new_window";
#                         "cmd+]" = "next_window";
#                         "cmd+[" = "previous_window";
#                     };

#                     themeFile = "Catppuccin-Mocha";

#                     settings =
#                         let
#                             font-features = "+ss02 +ss09 +ss07";
#                         in
#                         {

#                             cursor_shape = "beam"; # Make cursor look like |
#                             enabled_layouts = "tall:bias=50;full_size=1;mirrored=false"; # Enable tall layout priority w/ multiple terminals

#                             # Make windows close when OS asks them to close, even if running a process.
#                             # NOTE: We do this because we use zellij (terminal multiplexer) and so it's
#                             # kinda pointless to ask anyways.
#                             confirm_os_window_close = 0;

#                             # Font features/ligatures
#                             # NOTE: run `kitty --debug-font-fallback` to get the PostScript name of the font you
#                             # are using...
#                             "font_features FiraCodeNFM-Reg" = font-features;
#                             "font_features FiraCodeNFM-Bd" = font-features;
#                             "font_features FiraCodeNFM-SemBd" = font-features;
#                             "font_features FiraCodeNFM-Ret" = font-features;

#                             # Font fixes
#                             "modify_font cell_width" = "+0px";
#                             "modify_font cell_height" = "+0px";

#                             # MacOS tweaks
#                             macos_quit_when_last_window_closed = true; # See: https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.macos_quit_when_last_window_closed
#                             macos_colorspace = "displayp3"; # See: https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.macos_colorspace
#                         };
#                 };
#             };
#         };
# }
