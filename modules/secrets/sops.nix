{ inputs, ... }:
let
    shared = { pkgs, ... }: {
        environment.systemPackages = [
            pkgs.sops
            pkgs.age
        ];

        sops = {
            defaultSopsFile = ../../.sops.yaml;

            # WARN: `sops.age.sshKeyPaths` and `sops.age.keyFile` must be set at the host level! See
            # relevant `modules/hosts/*` files there.
            #
            # WARN: `sops.secrets` must be set at the host level! See relevant `modules/hosts/*`
            # files there.
        };
    };
in
{
    flake.modules.nixos.secrets = {
        imports = [
            inputs.sops-nix.nixosModules.sops
            shared
        ];
    };

    flake.modules.darwin.secrets = {
        imports = [
            inputs.sops-nix.darwinModules.sops
            shared
        ];
    };
}
