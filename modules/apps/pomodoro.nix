{
    flake.modules.homeManager."apps/pomodoro" = { pkgs, ... }: {
        home.packages = (if pkgs.stdenv.hostPlatform.isLinux then with pkgs; [ pomodoro-gtk ] else [ ]);
    };

    flake.modules.darwin."apps/pomodoro" = {
        homebrew.masApps = {
            "Tomito" = 1526042938;
        };
    };
}
