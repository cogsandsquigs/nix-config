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
            ];
        };

    # NOTE: currently nix-darwin can't manage steam, so we just use homebrew to install it for now.
    flake.modules.darwin.games =
        { ... }:
        {
            homebrew = {
                casks = [ "steam" ];
            };
        };

    flake.modules.nixos.games =
        { ... }:
        {
            programs.steam = {
                enable = true;
            };
        };
}
