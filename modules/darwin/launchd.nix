{pkgs, ...}: {
  launchd.user.agents = {
    raycast = {
      command = "${pkgs.raycast}";
    };
  };
}
