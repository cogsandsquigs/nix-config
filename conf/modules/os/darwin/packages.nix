# Extra system packages for a darwin desktop.
{
    darwin =
        {
            inputs,
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
                environment.systemPackages =
                    with inputs.nix-darwin.packages.${pkgs.stdenv.hostPlatform.system};
                    with pkgs;
                    [
                        # Nix-darwin pkgs
                        darwin-option
                        darwin-rebuild
                        darwin-version
                        darwin-uninstaller

                        # Regular, base pkgs
                        openssl # TODO: Why?
                        pinentry_mac # EZ pinentry for GPG
                        appcleaner # For cleaning up rogue `.app`s # NOTE: Currently has SHA mismatch
                    ];

                homebrew = {
                    brews = [
                        # bun's bundled TLS wants a system cert bundle at a path macOS does not
                        # provide, so `bun install` fails on certificate verification without this.
                        "ca-certificates"
                        "tccutil" # Manage TCC (e.g. "Full Disk Access") from CMDLINE. NOTE: Requires SIP disabled, otherwise won't work.
                    ];
                };
            };
        };
}
