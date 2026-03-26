# Expands the `base` system to desktop configurations

{ inputs, ... }:
{
    flake.modules.nixos.desktop = {
        imports = with inputs.self.modules.nixos; [ base ];
    };
}
