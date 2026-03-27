# Games commonly used.
{ ... }:
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
}
