# Development environments and languages tools (formatters, LSPs, etc.)

{ inputs, ... }:
{
    flake.modules.homeManager.develop =
        { pkgs, ... }:
        {
            imports = with inputs.self.modules.homeManager; [
                ide
                editor
                containers
                direnv
            ];

            home.packages = with pkgs; [
                # Benchmarking
                hyperfine
            ];
        };
}
