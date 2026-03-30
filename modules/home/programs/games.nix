# Games commonly used.
{ ... }:
let
    # Fills in `programs.steam`
    steamConf = {
        enable = true;
    };
in
{
    flake.modules.homeManager.games =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                # Minecraft
                prismlauncher

                # Celeste mod loader
                # olympus # NOTE: for some reason not supported on nix aarch64-darwin (?)

                # NOTE: See: https://nixos.wiki/wiki/Steam
                #steam
                #steam-run
            ];
        };

    flake.modules.darwin.games =
        { ... }:
        {
            programs.steam = steamConf;
        };

    flake.modules.nixos.games =
        { ... }:
        {
            programs.steam = steamConf;
        };
}
