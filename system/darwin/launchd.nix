# NOTE: See:
#   - https://www.danielcorin.com/til/nix-darwin/launch-agents/
#   - https://daiderd.com/nix-darwin/manual/index.html#opt-launchd.user.agents._name_.serviceConfig
#   - https://daiderd.com/nix-darwin/manual/index.html#opt-launchd.user.agents._name_.serviceConfig.StartCalendarInterval
#   - https://daiderd.com/nix-darwin/manual/index.html#opt-launchd.user.agents._name_.serviceConfig.StartInterval
{pkgs, ...}: {
    launchd.user.agents = {
        # Open raycast on startup
        raycast = {
            command = "open ${pkgs.raycast}/Applications/Raycast.app";

            serviceConfig = {
                KeepAlive = false; # When it stops, do *NOT* restart it (otherwise it just keeps opening lmao :p)
                RunAtLoad = true;
                StandardOutPath = "/tmp/raycast.out.log";
                StandardErrorPath = "/tmp/raycast.err.log";
            };
        };

        # Open tailscale on startup
        tailscale = {
            command = "open /Applications/Tailscale.app";

            serviceConfig = {
                KeepAlive = false; # When it stops, do *NOT* restart it (otherwise it just keeps opening lmao :p)
                RunAtLoad = true;
                StandardOutPath = "/tmp/tailscale.out.log";
                StandardErrorPath = "/tmp/tailscale.err.log";
            };
        };

        # Collect nix garbage
        nix-collect-garbage = {
            command = "python3 /etc/nix/scripts/sysutil/run.py cleanup";

            serviceConfig = {
                KeepAlive = false; # When it stops, do *NOT* restart it
                RunAtLoad = false;

                # # Run every week on sunday at midnight
                # StartCalendarInterval = {
                #     Minute = 0;
                #     Hour = 0;
                #     Weekday = 0;
                # };

                # Run every 24 hours
                StartInterval = 86400;

                StandardOutPath = "/tmp/nix-collect-garbage.out.log";
                StandardErrorPath = "/tmp/nix-collect-garbage.err.log";
            };
        };

        # Update and upgrade the system
        upgrade-system = {
            command = "python3 /etc/nix/scripts/sysutil/run.py cleanup";

            serviceConfig = {
                KeepAlive = false; # When it stops, do *NOT* restart it
                RunAtLoad = true;

                # Run every 6 hours
                StartInterval = 21600;

                StandardOutPath = "/tmp/upgrade-system.out.log";
                StandardErrorPath = "/tmp/upgrade-system.err.log";
            };
        };
    };
}
