{ inputs, ... }: {
    flake.modules.darwin.tools.determinate = {
        imports = [ inputs.determinate.darwinModules.default ];
        nix.enable = false; # Determinate Nix handles the Nix configuration
    };
}
