# This defines any and all flake-parts required for this dendritic configuration
{ inputs, ... }: {
    imports = [ inputs.flake-parts.flakeModules.modules ];

    config = {
        systems = [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
        ];
    };
}
