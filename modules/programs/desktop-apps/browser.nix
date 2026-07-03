{ ... }: {
    flake.modules.homeManager.desktop-apps.browser = { config, pkgs, ... }: {
        # NOTE: Add when ladybird browser becomes stable!!
        # home.packages = with pkgs; [ ladybird ];
    };

    flake.modules.darwin.desktop-apps.browser = { config, pkgs, ... }: {
        homebrew = {
            casks = [ "firefox" ];
        };
    };
}
