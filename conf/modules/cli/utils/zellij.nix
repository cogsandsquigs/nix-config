{
    home = { lib, config, ... }: {
        config = lib.mkIf config.my.user.cli.utils.enable {
            programs.zellij = {
                enable = true;

                enableZshIntegration = true;
                enableFishIntegration = true; # For some reason zellij is slow rn?
                enableBashIntegration = true;

                exitShellOnExit = true; # If autostarted w/ shell, exit shell on zellij exit

                settings = {
                    theme = "catppuccin-mocha";
                    show_startup_tips = false;
                    pane_frames = false; # Removes the border around panes
                    on_force_close = "quit"; # Quit when term window is quit, prevents zellij from hanging around when not wanted.
                    session_serialization = false; # Stop zellij from saving sessions
                    default_layout = "simple"; # NOTE: See `layouts` below.

                    # UI Settings
                    ui = {
                        # NOTE: Even though we set top-level pane-frames `false` (not displayed),
                        # if they are (i.e. floating pane) then we have them rounded
                        pane_frames.rounded_corners = true;
                    };
                };

                # Custom layouts, written as KDL (https://kdl.dev/).
                layouts = {
                    # Simple layout! gets rid of the bottom/top bars, since I made a Zellij
                    # integration for Starship (shows info n stuff!).
                    simple = {
                        layout = {
                            # panes can be bare
                            pane = { };
                        };
                    };
                };
            };
        };
    };
}
