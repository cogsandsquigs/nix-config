# Desktop apps commonly used.
{ inputs, ... }:
{
    flake.modules.homeManager.desktop-apps =
        { pkgs, ... }:
        {
            imports = with inputs.self.modules.homeManager; [
                browser
                torrenting
            ];

            home.packages = with pkgs; [
                # Productivity
                discord # currently on macos gets stuck on launch, keeps trying 2 upd (???) ptb and canary don't fix issue
                obsidian
                zoom-us
                notion-app

                # Fun
                #spotify
            ];
        };
}
