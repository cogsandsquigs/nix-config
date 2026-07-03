# Secrets configuration and such

{ inputs, ... }: {
    flake.modules.darwin.tools.secrets = { pkgs, ... }: {
        imports = [ inputs.agenix.darwinModules.default ];
        environment.systemPackages = [
            inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
    };

    flake.modules.nixos.tools.secrets = { pkgs, ... }: {
        imports = [ inputs.agenix.nixosModules.default ];
        environment.systemPackages = [
            inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
    };

    flake.modules.homeManager.tools.secrets = { ... }: {
        imports = [ inputs.agenix.homeManagerModules.default ];
    };
}
