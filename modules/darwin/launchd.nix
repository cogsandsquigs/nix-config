{pkgs, ...}: {
  launchd.user.agents = {
    raycast = {
      command = "${pkgs.raycast}";
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/tmp/raycast.out.log";
        StandardErrorPath = "/tmp/raycast.err.log";
      };
    };
  };
}
