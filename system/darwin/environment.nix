{
    pkgs,
    specialArgs,
    username,
    hostname,
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
    system.defaults.smb.NetBIOSName = hostname;

    users.users."${username}" = {
        home = "/Users/${username}";
        description = specialArgs.username;
        shell = pkgs.fish; # Default shell
    };

    nix.settings.trusted-users = [specialArgs.username];
}
