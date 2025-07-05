{pkgs, ...}: {
    programs.helix = {
        enable = true;
        package = pkgs.helix;

        # General settings
        # See: https://docs.helix-editor.com/configuration.html
        settings = {
            theme = "Catppuccin-Mocha";
        };

        # Language-specific settings
        # See: https://docs.helix-editor.com/languages.html
        languages = {
            # Language-server settings.
            language-server = {};

            # Language configurations for each language.
            language = [];
        };
    };
}
