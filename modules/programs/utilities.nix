{ ... }:
{
    flake.modules.homeManager.utilities =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                fzf
                ripgrep
                jq
                just
                tree
                magic-wormhole
                fontconfig
                inetutils
                eza
                dust
                bat
                zoxide
                lazygit
                fastfetch
            ];
        };
}
