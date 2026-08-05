# Host identity for glorpbox (the personal NixOS tower) -- see hosts/glorpbook/id.nix for the
# convention. Checked against the schema in tools/fleet.nix.
{
    class = "nixos";
    system = "x86_64-linux";
    users = [ "cogs" ];
}
