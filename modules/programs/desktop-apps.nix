# Desktop apps commonly used.
{ ... }:
{
    flake.modules.homeManager.desktop-apps =
        { pkgs, ... }:
        {
            home.packages = with pkgs; [
                # Productivity
                obsidian
                zoom-us

                # Benchmarking
                hyperfine
            ];
        };
}
