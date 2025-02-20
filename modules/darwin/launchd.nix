# NOTE: See:
#   - https://www.danielcorin.com/til/nix-darwin/launch-agents/
{pkgs, ...}: {
  launchd.user.agents = {
    raycast = {
      command = "${pkgs.raycast}/Applications/Raycast.app";
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/tmp/raycast.out.log";
        StandardErrorPath = "/tmp/raycast.err.log";
      };
    };
  };
}
