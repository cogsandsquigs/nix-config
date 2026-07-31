# `primaryUser` is not one of this host's own users.
{
    class = "nixos";
    system = "x86_64-linux";
    users = [ "someone" ];
    primaryUser = "elsewhere";
}
