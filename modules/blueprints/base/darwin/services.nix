{ ... }:
{

    # default settings needed for all darwinConfigurations
    flake.modules.darwin.base =
        { pkgs, ... }:
        {

            services = {
                # openssh = {
                #     # Let Nix (nix-darwin) manage the default MacOS OpenSSH server. Set this to
                #     # `null` to let MacOS manage the MacOS OpenSSH server.
                #     enable = true;
                # };
            };

        };
}
