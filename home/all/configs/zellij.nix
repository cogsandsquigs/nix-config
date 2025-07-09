{pkgs, ...}: {
    programs.zellij = {
        enable = true;
        enableZshIntegration = true;
        enableFishIntegration = false; # For some reason zellij is slow rn?
        enableBashIntegration = true;

        package = pkgs.zellij;

        settings = {
            theme = "catppuccin-mocha";
        };
    };
}
