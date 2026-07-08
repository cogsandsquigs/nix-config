# Baseline home-manager settings needed on every machine.
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

    # Home-manager manpages (`man home-configuration.nix`). Kept ON deliberately.
    #
    # KNOWN NOISE: with this enabled, every eval/rebuild prints a warning like
    #   warning: Using 'builtins.derivation' to create a derivation named 'options.json' that
    #   references the store path '/nix/store/…-source' without a proper context. …
    # It comes from home-manager's manual generation: building the manpages runs
    # `nixosOptionsDoc`, which produces an `options.json` derivation that references the flake
    # source path without string context. Under Determinate Nix's `lazy-trees` feature that
    # pattern is flagged. It is benign — it only concerns the *docs* derivation's store-reference
    # tracking, never the actual home environment.
    #
    # There is no config-only way to keep the manpages AND silence the warning: the only levers
    # are turning the manpages off (`manual.manpages.enable = false`) or disabling `lazy-trees`.
    # We want the manpages, so we accept the warning.
    manual.manpages.enable = true;

    # VPN client
    home.packages = with pkgs; [ openvpn ];
}
