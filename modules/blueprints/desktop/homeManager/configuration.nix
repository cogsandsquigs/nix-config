# Expands the `base` system to desktop configurations

{ inputs, ... }:
{
    flake.modules.homeManager.desktop = {
        imports = with inputs.self.modules.homeManager; [ base ];
    };
}
