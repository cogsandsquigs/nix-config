{
    flake.modules.homeManager."games/minecraft" = { pkgs, ... }: {
        home.packages = with pkgs; [ prismlauncher ]; # NOTE: wrapped ver. has issue w/ extra-cmake-modules not supporting macos
    };
}
