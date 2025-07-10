{ pkgs, ... }:
{
    imports = [
        ./configs
        ./packages
    ];

    home = {
        stateVersion = "25.05"; # Home Manager version
        packages = with pkgs; [ home-manager ];
    };

    nixpkgs.config.allowUnfree = true;
}
