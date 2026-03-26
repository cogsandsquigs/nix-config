{ inputs, ... }:
{
    flake.modules.darwin."Ians-GlorpBook-Pro" = {
        home-manager = {
            backupCommand = "rm";
            backupFileExtension = "bak";
            users.cogs.imports = with inputs.self.modules.homeManager; [
                desktop
                cogs
            ];
        };
    };
}
