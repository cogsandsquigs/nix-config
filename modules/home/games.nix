# Games commonly used.
{ ... }: {
  flake.modules.homeManager.games = { pkgs, ... }: {
    home.packages = with pkgs; [
      # Minecraft
      prismlauncher # NOTE: wrapped ver. has issue w/ extra-cmake-modules not supporting macos

      # Mod manager/launcher for KSP
      ckan

      # Celeste mod loader
      #olympus # NOTE: for some reason not supported on nix aarch64-darwin (?)
    ];
  };

  # NOTE: currently nix-darwin can't manage steam, so we just use homebrew to install it for now.
  flake.modules.darwin.games = { ... }: {
    homebrew = {
      casks = [
        "steam"
        "olympus" # Celeste mod loader # NOTE: for some reason not supported on nix aarch-64
        "porting-kit" # Windows -> Mac games
      ];
    };
  };

  flake.modules.nixos.games = { ... }: {
    programs.steam = {
      enable = true;
    };
  };
}
