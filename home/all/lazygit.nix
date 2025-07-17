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
        "${catppuccin-theme}/themes/mocha/sapphire.yaml,$(lazygit --print-config-dir)";
}
