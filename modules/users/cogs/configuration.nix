{ inputs, ... }:
let
    username = "cogs";
in
{
    flake.modules.nixos.${username} = {
        imports = with inputs.self.modules.nixos; [ home-manager ];

        users.users.${username} = {
            group = "wheel";
        };
    };

    flake.modules.darwin.${username} = {
        imports = with inputs.self.modules.darwin; [ home-manager ];
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
