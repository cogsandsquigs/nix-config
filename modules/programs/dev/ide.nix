{ ... }: {

    flake.modules.homeManager.dev.ide = { pkgs, ... }: {
        home.packages = with pkgs; [ jetbrains.idea ];
    };
}
