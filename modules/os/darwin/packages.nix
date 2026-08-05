# Extra system packages for a darwin desktop.
{
    darwin =
        {
            pkgs,
            lib,
            config,
            tools,
            ...
        }:
        {
            options.my.sys.os.darwin.packages.enable =
                tools.opt.mkEnabled "extra darwin system packages (pinentry_mac, appcleaner)";

            config = lib.mkIf config.my.sys.os.darwin.packages.enable {
                environment.systemPackages = with pkgs; [
                    pinentry_mac # EZ pinentry for GPG
                    # appcleaner # For cleaning up rogue `.app`s # NOTE: Currently has SHA mismatch
                ];
            };
        };
}
