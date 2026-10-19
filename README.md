# nix-config

My nix configuration.

## Layout

- `modules/`: dendritic nix modules
    - `*.nix`: Top-level, general configuration
    - `parts.nix`: All flake-parts used in this dendritic config, including:
        - `modules` (builtin): Using `modules.darwin`, `modules.nixos`, `modules.home` instead of
          uglier syntax.
    - `hosts/`: Host configurations. Each host has its own directory.
    - `apps/`: Application-specific configuration. This includes CLI, GUI, etc.
    - `games/`: Games and video-gaming configuration. Separate from apps due to complexity, etc.
    - `services/`: Services, background or otherwise. Differentiated from `apps/` by the fact that
      they mostly do work in the background, even if they have a GUI/app associated with it.
    - `sessions/`: Configuration for desktop sessions. `sessions/macos` is for macos desktop config.
    - `secrets/`: Secrets to be used for machines.
