{
    pkgs,
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
    networking.hostName = hostname;
    networking.computerName = hostname;
    system.defaults.smb.NetBIOSName = hostname;

    users.users."${username}" = {
        home = "/Users/${username}";
        description = username;
        shell = pkgs.fish; # Default shell
    };

    nix.settings.trusted-users = [username];
}
