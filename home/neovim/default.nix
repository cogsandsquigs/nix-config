{
  programs.neovim = {
    enable = true;
  };

  # Normal LazyVim config here, see https://github.com/LazyVim/starter/tree/main/lua
  xdg.configFile = {
    "nvim/lua".source = ./lua;
    "nvim/init.lua".source = ./init.lua;
  };
}
