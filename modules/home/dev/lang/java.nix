{ ... }:
{
  flake.modules.homeManager.dev.lang =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        jdk
        gradle
        kotlin
      ];
    };
}
