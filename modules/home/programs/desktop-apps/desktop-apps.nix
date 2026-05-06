# Desktop apps commonly used.
{ inputs, ... }:
{
    flake.modules.homeManager.desktop-apps =
        { pkgs, ... }:
        {
            imports = with inputs.self.modules.homeManager; [ browser ];

            home.packages = with pkgs; [
                # Productivity
                #discord # see below: currently, gets stuck on launch, keeps trying 2 upd (???)
                discord-canary # Wait for discord to upd. proper?
                obsidian
                zoom-us

                # Fun
                spotify
            ];
        };
}
