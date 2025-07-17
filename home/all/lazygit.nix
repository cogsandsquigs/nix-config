{ pkgs, ... }:
{
    home.packages = with pkgs; [
        lazygit # Makes git awesomer
    ];

    programs.lazygit = {
        enable = true;
        package = pkgs.lazygit;
        # NOTE: Any settings we want here.
        settings = { };
    };

    # NOTE: This allows us to merge both our nix-defined config, as well as the
    # nice and juicy catppuccin one.
    home.sessionVariables.LG_CONFIG_FILE =
        let
            catppuccin-theme = pkgs.fetchgit {
                url = "https://github.com/catppuccin/lazygit.git";
                # NOTE: Less space taken since we only use part.
                # WARN: If we wanna change the path to the theme, we gotta change this too!
                sparseCheckout = [ "themes" ];
                hash = "sha256-aKK4UUjVoniScVYp0AbpTukZeAZWZOA/eb+Vb0LhrfQ=";
            };
        in
        # NOTE: Oyr configuration (specified in `settings`) ends in .yml.
        # See: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.lazygit.settings
        # Also, we put quotes since MacOS path includes `Application Support` or whatev.
        "${catppuccin-theme}/themes/mocha/sapphire.yml,$(lazygit --print-config-dir)/config.yml";

}
