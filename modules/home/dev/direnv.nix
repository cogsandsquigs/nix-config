{
    pkgs,
    lib,
    config,
    tools,
    ...
}:
{
    options.my.user.dev.direnv.enable = tools.mkRiding config.my.user.dev.enable "direnv + nix-direnv";

    config = lib.mkIf config.my.user.dev.direnv.enable {
        home.packages = with pkgs; [ direnv ];

        programs.direnv = {
            enable = true;

            # Enable nix-direnv integration. See:
            # https://github.com/nix-community/nix-direnv
            nix-direnv.enable = true;

            # Integrate with shells
            enableBashIntegration = true;
            enableZshIntegration = true;
            #enableFishIntegration = true; # ? Read-only?
        };
    };
}
