{
    flake.modules.homeManager."apps/pomodoro" = { pkgs, ... }: {
        home.packages = with pkgs; [ pomodoro-gtk ];
    };
}
