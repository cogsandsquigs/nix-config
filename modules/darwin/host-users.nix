{specialArgs, ...}:
#############################################################
#
#  Host & Users configuration
#
#############################################################
let
  # username = "cogs";
  #hostname = "Ians-GlorpBook-Pro";
in {
  networking.hostName = specialArgs.hostname;
  networking.computerName = specialArgs.hostname;
  system.defaults.smb.NetBIOSName = specialArgs.hostname;

  users.users."${specialArgs.username}" = {
    home = "/Users/${specialArgs.username}";
    description = specialArgs.username;
  };

  nix.settings.trusted-users = [specialArgs.username];
}
