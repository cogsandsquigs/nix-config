# Antivirus (Linux only).
{
    nixos =
        {
            pkgs,
            lib,
            config,
            tools,
            ...
        }:
        {
            options.my.sys.nixos.security.enable =
                tools.opt.mkEnabled "ClamAV antivirus (daemon + scanner + updater)";

            config = lib.mkIf config.my.sys.nixos.security.enable {
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
        };
}
