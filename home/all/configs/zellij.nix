{pkgs, ...}: {
    programs.zellij = {
        enable = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        enableBashIntegration = true;

        package = pkgs.zellij;

        settings = {
            theme = "catppuccin-macciato";
        };
    };
}
