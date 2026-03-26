{ ... }:
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
            # NOTE: Must be 25.05 for now, not 25.11 (latest). Otherwise, home-manager activation
            # fails at checkAppManagementPermission.
            #
            # See: https://github.com/nix-community/home-manager/issues/8336
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
