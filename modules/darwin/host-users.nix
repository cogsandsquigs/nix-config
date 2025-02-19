{...}:
#############################################################
#
#  Host & Users configuration
#
#############################################################
let
  username = "ianpratt";
  platform = "aarch64-darwin"; # aarch64-darwin or x86_64-darwin
  hostname = "Ians-GlorpBook-Pro";
in {
  networking.hostName = hostname;
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;

  users.users."${username}" = {
    home = "/Users/${username}";
    description = username;
  };

  nix.settings.trusted-users = [username];
}
