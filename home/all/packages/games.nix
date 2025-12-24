{ pkgs, ... }:
{
    home.packages = with pkgs; [
        # Games
        # NOTE: See: https://nixos.wiki/wiki/Steam
        #steam
        #steam-run

        modrinth-app-unwrapped # Minecraft launcher
        prismlauncher-unwrapped
    ];
}
