{ inputs, ... }:
{
    flake.modules.homeManager.utilities =
        { pkgs, ... }:
        {
            imports = with inputs.self.modules.homeManager; [
                gpg
                direnv
            ];

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
