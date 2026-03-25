{ inputs, ... }:
{
    # default settings needed for all homeManagerConfigurations
    flake.modules.homeManager.base =
        {
            config,
            pkgs,
            lib,
            ...
        }:
        {
            imports = with inputs.self.modules.homeManager; [
                shell
                starship
                editor
                zellij
                utilities
                direnv
                gpg
            ];

            home.stateVersion = "25.05";
            home.homeDirectory =
                if pkgs.stdenv.isDarwin then
                    (lib.mkForce "/Users/${config.home.username}")
                else
                    "/home/${config.home.username}";

            # TODO: Get rid of once actual prog. lang. pkg/conf setup has been achieved.
            home.packages = with pkgs; [
                nixfmt # Official/default formatter
                nixd # Official (community) Nix LSP
                nil # Unofficial Nix LSP
            ];

            programs.home-manager.enable = true;
        };
}
