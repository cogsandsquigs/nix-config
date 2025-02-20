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
  };
}
