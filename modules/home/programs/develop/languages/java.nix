{ ... }:
{
    flake.modules.homeManager.develop =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                jdk
                gradle
                kotlin
            ];
        };
}
