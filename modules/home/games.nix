# Games commonly used.
{ pkgs, ... }: {
    home.packages = with pkgs; [
        # Minecraft
        prismlauncher # NOTE: wrapped ver. has issue w/ extra-cmake-modules not supporting macos

        # Mod manager/launcher for KSP
        ckan

        # Celeste mod loader
        #olympus # NOTE: for some reason not supported on nix aarch64-darwin (?)
    ];
}
