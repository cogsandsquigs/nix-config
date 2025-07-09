{pkgs, ...}: {
    programs.zellij = {
        enable = true;
        enableZshIntegration = true;
        enableFishIntegration = false; # ?
        enableBashIntegration = true;

        package = pkgs.zellij;

        settings = {
            theme = "catppuccin-mocha";
        };
    };
}
