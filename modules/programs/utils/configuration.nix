{ inputs, ... }: {
    flake.modules.homeManager.utils = { pkgs, ... }: {
        imports = with inputs.self.modules.homeManager.utils; [
            gpg
            yazi
            zellij
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

        programs.eza = {
            colors = "auto";
            git = true;
            icons = true;
        };

        programs.zoxide = {
            enable = true;
            enableZshIntegration = true;
            enableFishIntegration = true;
        };
    };
}
