{
    pkgs,
    inputs,
    ...
}: let
    inputs.zjstatus.url = "github:dj95/zjstatus";
in {
    programs.zellij = {
        enable = true;
        package = pkgs.zellij;

        enableZshIntegration = true;
        enableFishIntegration = true; # For some reason zellij is slow rn?
        enableBashIntegration = true;

        exitShellOnExit = true; # If autostarted w/ shell, exit shell on zellij exit

        settings = {
            theme = "catppuccin-mocha";
        };
    };
}
