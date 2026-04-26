# Development environments and languages tools (formatters, LSPs, etc.)

{ inputs, ... }:
{
    flake.modules.homeManager.desktop =
        { pkgs, ... }:
        {
            imports = with inputs.self.modules.homeManager; [
                ide
                editor
                containers
                # direnv # NOTE: currently has weird issue get stuck during build?
            ];

            home.packages = with pkgs; [
                # Benchmarking
                hyperfine
            ];
        };
}
