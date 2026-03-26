# Desktop apps commonly used.
{ inputs, ... }:
{
    flake.modules.homeManager.desktop-apps =
        { pkgs, ... }:
        {
            imports = with inputs.self.modules.homeManager; [ browser ];

            home.packages = with pkgs; [
                # Productivity
                obsidian
                zoom-us
            ];
        };
}
