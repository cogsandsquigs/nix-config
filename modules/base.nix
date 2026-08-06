# Baseline home-manager settings needed on every machine.
{
    home =
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

            programs.home-manager.enable = true;

            # Manpages (`man home-configuration.nix`), kept on deliberately.
            #
            # KNOWN NOISE: this makes every eval print `warning: Using 'builtins.derivation' to create a
            # derivation named 'options.json' [...] without a proper context`. Building the manpages runs
            # `nixosOptionsDoc`, whose `options.json` references the flake source without string context,
            # which Determinate's `lazy-trees` flags. It concerns that docs derivation's store-reference
            # tracking only, never the home environment. The only levers are dropping the manpages or
            # dropping `lazy-trees`, so the warning stands.
            manual.manpages.enable = true;
        };
}
