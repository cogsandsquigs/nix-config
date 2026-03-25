{ inputs, ... }:
{

    # NOTE: See:
    #   - https://www.danielcorin.com/til/nix-darwin/launch-agents/
    #   - https://daiderd.com/nix-darwin/manual/index.html#opt-launchd.user.agents._name_.serviceConfig
    #   - https://daiderd.com/nix-darwin/manual/index.html#opt-launchd.user.agents._name_.serviceConfig.StartCalendarInterval
    #   - https://daiderd.com/nix-darwin/manual/index.html#opt-launchd.user.agents._name_.serviceConfig.StartInterval
    flake.modules.darwin.macbook = {
        launchd.user.agents = {
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
        };
    };
}
