# NOTE: currently nix-darwin can't manage steam, so we just use homebrew to install it for now.
{
  lib,
  config,
  tools,
  ...
}:
{
  options.my.sys.games.enable =
    tools.opt.mkDisabled "games (Steam, Olympus, Porting Kit via Homebrew)";

  config = lib.mkIf config.my.sys.games.enable {
    homebrew = {
      casks = [
        "steam"
        "olympus" # Celeste mod loader # NOTE: for some reason not supported on nix aarch-64
        "porting-kit" # Windows -> Mac games
      ];
    };
  };
}
