{
    pkgs,
    specialArgs,
    ...
}:
#############################################################
#
#  Host & Users configuration
#
#############################################################
{
    networking.hostName = specialArgs.hostname;
    networking.computerName = specialArgs.hostname;
    system.defaults.smb.NetBIOSName = specialArgs.hostname;

    users.users."${specialArgs.username}" = {
        home = "/Users/${specialArgs.username}";
        description = specialArgs.username;
        shell = pkgs.fish; # Default shell
    };

    nix.settings.trusted-users = [specialArgs.username];
}
