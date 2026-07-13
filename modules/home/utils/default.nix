# General CLI utilities.
{
    pkgs,
    lib,
    config,
    tools,
    ...
}:
{
    imports = [
        ./gpg.nix
        ./gpg-agent.nix
        ./yazi.nix
        ./zellij.nix
    ];

    options.my.user.utils.enable =
        tools.opt.mkEnabled "CLI utilities (gpg, yazi, zellij, fzf, ripgrep, eza, …)";

    config = lib.mkIf config.my.user.utils.enable {
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
