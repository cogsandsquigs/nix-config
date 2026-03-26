# Development environments and languages tools (formatters, LSPs, etc.)

{ inputs, ... }:
{
    flake.modules.homeManager.develop =
        { ... }:
        {
            imports = with inputs.self.modules.homeManager; [
                ide
                editor
                containers
            ];
        };
}
