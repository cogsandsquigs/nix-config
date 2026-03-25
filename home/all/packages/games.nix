{ pkgs, ... }:
{
    home.packages = with pkgs; [
        # Games
        # NOTE: See: https://nixos.wiki/wiki/Steam
        #steam
        #steam-run

        prismlauncher # Minecraft launcher
    ];
}
