{ inputs, ... }:
{
    flake.modules.darwin."Ians-GlorpBook-Pro" = {
        home-manager = {
            backupFileExtension = "bak";
            users.cogs.imports = with inputs.self.modules.homeManager; [ cogs ];
        };
    };
}
