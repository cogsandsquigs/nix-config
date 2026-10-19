{ self, ... }: {
    flake.modules.nixos.services = {
        imports = [ self.modules.nixos."services/tailscale" ];
    };

    flake.modules.darwin.services = {
        imports = [ self.modules.darwin."services/tailscale" ];
    };
}
