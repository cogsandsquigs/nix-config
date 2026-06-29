{
    flake.modules.darwin.base = { };
    flake.modules.nixos.base = { pkgs, ... }: {
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
