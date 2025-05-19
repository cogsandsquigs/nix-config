{
    programs.neovim = {
        enable = true;
    };

    # Normal LazyVim config here, see https://github.com/LazyVim/starter/tree/main/lua
    xdg.configFile = {
        "nvim/lua".source = ./lua;
        "nvim/init.lua".source = ./init.lua;
    };

    # NOTE: Necessary for clang-format to always have same config/formatting rules, etc. everywhere
    home.file = {
        ".clang-format".source = ./.clang-format;
    };
}
