# Kitty terminal. (zellij lives in ./utils, which is imported alongside this module.)
{
  pkgs,
  lib,
  config,
  tools,
  ...
}:
{
  options.my.user.terminal.enable = tools.opt.mkEnabled "kitty terminal";

  config = lib.mkIf config.my.user.terminal.enable {
    home.packages = with pkgs; [ kitty ];

    programs.kitty = {
      enable = true;

      darwinLaunchOptions = [ "--start-as fullscreen" ];

      font = {
        name = "FiraCode Nerd Font Mono";
        package = pkgs.nerd-fonts.fira-code;
        size = 13;
      };

      keybindings = {
        # Linux keybinds
        "super+d" = "new_window";
        "super+]" = "next_window";
        "super+[" = "previous_window";

        # MacOS keybinds
        "cmd+d" = "new_window";
        "cmd+]" = "next_window";
        "cmd+[" = "previous_window";
      };

      themeFile = "Catppuccin-Mocha";

      settings =
        let
          font-features = "+ss02 +ss09 +ss07";
        in
        {

          cursor_shape = "beam"; # Make cursor look like |
          enabled_layouts = "tall:bias=50;full_size=1;mirrored=false"; # Enable tall layout priority w/ multiple terminals

          # Make windows close when OS asks them to close, even if running a process.
          # NOTE: We do this because we use zellij (terminal multiplexer) and so it's
          # kinda pointless to ask anyways.
          confirm_os_window_close = 0;

          # Font features/ligatures
          # NOTE: run `kitty --debug-font-fallback` to get the PostScript name of the font you
          # are using...
          "font_features FiraCodeNFM-Reg" = font-features;
          "font_features FiraCodeNFM-Bd" = font-features;
          "font_features FiraCodeNFM-SemBd" = font-features;
          "font_features FiraCodeNFM-Ret" = font-features;

          # Font fixes
          "modify_font cell_width" = "+0px";
          "modify_font cell_height" = "+0px";

          # MacOS tweaks
          macos_quit_when_last_window_closed = true; # See: https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.macos_quit_when_last_window_closed
          macos_colorspace = "displayp3"; # See: https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.macos_colorspace
        };
    };
  };
}
