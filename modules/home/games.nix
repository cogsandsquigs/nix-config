# Games commonly used.
{
    pkgs,
    lib,
    config,
    tools,
    ...
}:
{
    options.my.user.games.enable = tools.mkDisabled "games (Minecraft via Prism, KSP via CKAN, …)";

    config = lib.mkIf config.my.user.games.enable {
        home.packages = with pkgs; [
            # Minecraft
            prismlauncher # NOTE: wrapped ver. has issue w/ extra-cmake-modules not supporting macos

            # Mod manager/launcher for KSP
            ckan

            # Celeste mod loader
            #olympus # NOTE: for some reason not supported on nix aarch64-darwin (?)
        ];
    };
}
