# Development environments and languages tools (formatters, LSPs, etc.)

{ inputs, ... }:
{
    flake.modules.homeManager.desktop-apps =
        { ... }:
        {
            imports = with inputs.self.modules.homeManager; [
                ide
                editor
            ];
        };
}
