{ inputs, ... }:
let
    username = "cogs";
in

{
    flake.modules.darwin.macbook = {
        home-manager.users.${username}.imports = with inputs.self.modules.homeManager; [ cogs ];
    };
}
