# Tailscale, via the Homebrew cask.
#
# darwin only for now. NixOS has `services.tailscale.enable`. Add a `nixos` key when the personal Linux
# box exists.
#
# The cask and the login agent that opens it are ONE feature, under one `mkIf`. Split across two files,
# turning the feature off left an agent running `open` against an application
# `homebrew.onActivation.cleanup = "zap"` had just uninstalled.
{
    darwin =
        {
            lib,
            config,
            tools,
            ...
        }:
        {
            _class = "darwin";

            options.my.sys.net.tailscale.enable = tools.opt.mkDisabled "Tailscale (Homebrew cask)";

            config = lib.mkIf config.my.sys.net.tailscale.enable {
                homebrew.casks = [ "tailscale-app" ];

                # The cask has no login item of its own, so open the app at login.
                # See https://www.danielcorin.com/til/nix-darwin/launch-agents/ and the nix-darwin
                # manual's `launchd.user.agents.<name>.serviceConfig`.
                launchd.user.agents.tailscale = {
                    command = "open /Applications/Tailscale.app";

                    serviceConfig = {
                        # Do NOT restart it when it exits, or it reopens the app forever.
                        KeepAlive = false;
                        RunAtLoad = true;
                        StandardOutPath = "/tmp/tailscale.out.log";
                        StandardErrorPath = "/tmp/tailscale.err.log";
                    };
                };
            };
        };
}
