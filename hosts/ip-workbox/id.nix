# Host identity for work-desktop -- see hosts/glorpbook/id.nix for the convention. Checked against
# the schema in tools/fleet.nix.
#
# `class = "home"` is what makes this box standalone home-manager: per-user Nix, no system layer, so
# only its single user's home configuration applies and no system account is declared. The flake
# output is homeConfigurations."<primaryUser>@<name>".
{
    class = "home";
    system = "x86_64-linux";
    users = [ "ipratt" ];
}
