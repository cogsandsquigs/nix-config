{ inputs, ... }:
let
    username = "cogs";
in
{
    flake.modules.nixos.${username} = {
        imports = with inputs.self.modules.nixos; [
            # developmentEnvironment
        ];

        users.users.${username} = {
            group = "wheel";
        };
    };

    flake.modules.darwin.${username} = {
        imports = with inputs.self.modules.darwin; [ home-manager ];
    };

    flake.modules.homeManager.${username} =
        { pkgs, ... }:
        {
            imports = with inputs.self.modules.homeManager; [ desktop ];

            home.packages = with pkgs; [
                cowsay
                # mediainfo
            ];
        };
}
