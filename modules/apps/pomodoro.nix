{
    flake.modules.homeManager."apps/pomodoro" = { pkgs, ... }: {
        home.packages = (if pkgs.stdenv.hostSystem.isLinux then with pkgs; [ pomodoro-gtk ] else [ ]);
    };

    flake.modules.darwin."apps/pomodoro" = {
        homebrew.casks = [ "tomatobar" ];
    };
}
