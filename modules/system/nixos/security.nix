# Antivirus (Linux only).
{
  pkgs,
  lib,
  config,
  tools,
  ...
}:
{
  options.my.sys.security.enable =
    tools.opt.mkEnabled "ClamAV antivirus (daemon + scanner + updater)";

  config = lib.mkIf config.my.sys.security.enable {
    environment.systemPackages = with pkgs; [ clamav ];

    services = {
      clamav = {
        daemon = {
          enable = true;
          settings = {
            "LogSyslog" = true;
          };
        };

        scanner = {
          enable = true;
          interval = "4h";
        };

        updater = {
          enable = true;
          frequency = 4;
        };
      };
    };
  };
}
