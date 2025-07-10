{ pkgs, ... }:
{
  programs.neovim = {
    # enable = true;
    package = pkgs.neovim; # Necessary since by default programs.neovim.enable uses a different package
  };

  # Normal LazyVim config here, see https://github.com/LazyVim/starter/tree/main/lua
  xdg.configFile = {
    "nvim/lua".source = ./lua;
    "nvim/init.lua".source = ./init.lua;
  };
}
