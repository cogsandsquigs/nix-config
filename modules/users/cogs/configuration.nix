{ inputs, ... }:
let
    username = "cogs";
in
{
    flake.modules.nixos.${username} =
        { pkgs, ... }:
        {
            imports = with inputs.self.modules.nixos; [ home-manager ];

            users.users.${username} = {
                description = username;
                group = "wheel";
                shell = pkgs.fish;
            };
        };

    flake.modules.darwin.${username} =
        { pkgs, ... }:
        {
            imports = with inputs.self.modules.darwin; [ home-manager ];

            users.users.${username} = {
                description = username;
                shell = pkgs.fish;
            };
        };

    flake.modules.homeManager.${username} =
        { ... }:
        {
            imports = with inputs.self.modules.homeManager; [
                desktop

                # CLI utilities
                shell
                terminal
                utilities
                git-cogs

                # Desktop apps
                desktop-apps
                games

                # Development
                develop
            ];
        };
}
