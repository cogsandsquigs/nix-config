# Expands the `base` system to desktop configurations

{ inputs, ... }:
{

    flake.modules.nixos.desktop = {
        imports = with inputs.self.modules.nixos; [ base ];
    };

    flake.modules.darwin.desktop = {
        imports = with inputs.self.modules.darwin; [ base ];
    };

    flake.modules.homeManager.desktop = {
        imports = with inputs.self.modules.homeManager; [
            base

            desktop-apps
            games
        ];
    };
}
