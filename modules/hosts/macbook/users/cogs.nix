{ inputs, ... }:
let
    username = "cogs";
in

{
    flake.modules.darwin."Ians-GlorpBook-Pro" = {
        home-manager.users.${username}.imports = with inputs.self.modules.homeManager; [ cogs ];
    };
}
