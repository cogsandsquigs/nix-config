{
    inputs,
    lib,
    self,
    ...
}:
let
    username = "cogs";
in
{
    flake.modules.nixos.${username} = {
        imports = with self.modules.nixos; [
            # developmentEnvironment
        ];

        users.users.${username} = {
            group = "wheel";
        };
    };

    flake.modules.darwin.${username} = {
        imports = with self.modules.darwin; [
            # drawingApps
            # developmentEnvironment
        ];
    };

    flake.modules.homeManager.${username} =
        { pkgs, ... }:
        {
            imports = with self.modules.homeManager; [
                desktop
                # adminTools
                # vscode
                # passwordManager
            ];
            home.packages = with pkgs; [
                # mediainfo
            ];
        };
}
