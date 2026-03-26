{ inputs, ... }:
{

    # default settings needed for all darwinConfigurations
    flake.modules.darwin.base =
        { pkgs, ... }:
        {
            system.stateVersion = 6;

            environment.systemPackages =
                with inputs.nix-darwin.packages.${pkgs.stdenv.hostPlatform.system};
                with pkgs;
                [
                    # Nix-darwin pkgs
                    darwin-option
                    darwin-rebuild
                    darwin-version
                    darwin-uninstaller

                    # Regular, base pkgs
                    mkalias # TODO: Why?
                    openssl # TODO: Why?
                ];
        };
}
