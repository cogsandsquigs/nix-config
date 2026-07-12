# Desktop apps commonly used.
{
  pkgs,
  lib,
  config,
  tools,
  ...
}:
{
  imports = [ ./browser.nix ];

  options.my.user.desktopApps.enable =
    tools.opt.mkDisabled "personal GUI apps (Discord, Obsidian, Zoom, …)";

  config = lib.mkIf config.my.user.desktopApps.enable {
    home.packages = with pkgs; [
      # Productivity
      discord # currently on macos gets stuck on launch, keeps trying 2 upd (???) ptb and canary don't fix issue
      obsidian
      zoom-us
      qbittorrent

      # Fun
      #spotify
    ];
  };
}
