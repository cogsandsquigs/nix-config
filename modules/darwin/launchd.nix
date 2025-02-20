# NOTE: See:
#   - https://www.danielcorin.com/til/nix-darwin/launch-agents/
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
