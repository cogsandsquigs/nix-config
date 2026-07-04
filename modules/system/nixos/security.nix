# Antivirus (Linux only).
{ pkgs, ... }: {
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
}
