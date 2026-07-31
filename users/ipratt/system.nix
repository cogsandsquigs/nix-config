# System account for `ipratt` on a full-OS host -- see users/cogs/system.nix for the convention.
#
# The work box itself is standalone home-manager (no system layer), so this only matters if the work
# user is ever placed on a NixOS or nix-darwin host.
let
    account = {
        description = "ipratt";
    };
in
{
    nixos = { pkgs, ... }: {
        users.users.ipratt = account // {
            shell = pkgs.fish;
            isNormalUser = true;
            extraGroups = [ "wheel" ];
        };
    };

    darwin = { pkgs, ... }: {
        users.users.ipratt = account // {
            shell = pkgs.fish;
        };
    };
}
