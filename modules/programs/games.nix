# Games commonly used.
{ ... }:
{
    flake.modules.homeManager.games =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                # Minecraft
                prismlauncher

                # NOTE: See: https://nixos.wiki/wiki/Steam
                #steam
                #steam-run
            ];
        };
}
