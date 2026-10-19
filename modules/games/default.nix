{ self, ... }: {
    flake.modules.nixos.games = {
        imports = [ self.modules.nixos."games/steam" ];
    };

    flake.modules.darwin.games = {
        imports = [ self.modules.darwin."games/steam" ];
    };
}
