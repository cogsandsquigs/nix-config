{ inputs, ... }:
{
    flake.modules.nixos.base =
        { ... }:
        {
            imports = with inputs.self.modules.nixos; [ overlays ];
        };
}
