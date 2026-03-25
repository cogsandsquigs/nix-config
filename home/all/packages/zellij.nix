{ pkgs, ... }:
{
    home.packages = with pkgs; [ zellij ];

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
            default_layout = "simple"; # NOTE: See below (outside of `programs.zellij`)!

            # UI Settings
            ui = {
                # NOTE: Even though we set top-level pane-frames `false` (not displayed),
                # if they are (i.e. floating pane) then we have them rounded
                pane_frames.rounded_corners = true;
            };

        };

        ###############################################################
        # Custom layouts for Zellij!                                  #
        # NOTE: These layouts are written using KDL: https://kdl.dev/ #
        ###############################################################

        layouts = {
            # Simple layout! gets rid of the bottom/top bars, since I made a Zellij
            # integration for Starship (shows info n stuff!).
            simple = {
                layout = {
                    # panes can be bare
                    pane = { };
                };
            };

            # Uses `zjstatus` to create a (much nicer!) terminal status bar.
            # NOTE: Sets `__ZELLIJ_DONT_SHOW_STATUS` so that we know not to show it
            # in Starship.

            better =
                let
                    zjstatus = pkgs.fetchurl {
                        url = "https://github.com/dj95/zjstatus/releases/download/v0.21.0/zjstatus.wasm";
                        hash = "sha256-p6JTnAyim0T3TkJzGhEitzc3JpPovL5k7jb8gv+oLD4=";
                    };
                in
                {
                    env = {
                        __ZELLIJ_DONT_SHOW_STATUS = 0;
                    };

                    layout = {
                        # NOTE: We specify `_props` and `_children` so that we can write things like:
                        # 'pane size=1 borderless=true { ... }', where
                        # 'size=1 borderless=true' are the props and `{ ... }` are the children.
                        pane = {
                            _props = {
                                split_direction = "horizontal";
                            };
                            _children = [
                                {
                                    pane = {
                                        _props = {
                                            size = 1;
                                            borderless = true;
                                        };
                                        _children = [
                                            {
                                                plugin = {
                                                    _props = {
                                                        location = "file:${zjstatus}";
                                                    };
                                                    _children = [
                                                        {

                                                            format_left = "{mode} #[fg=#89B4FA,bold]{session}";
                                                            format_center = "{tabs}";
                                                            format_right = "{command_git_branch} {datetime}";
                                                            format_space = "";

                                                            border_enabled = "false";
                                                            border_char = "─";
                                                            border_format = "#[fg=#6C7086]{char}";
                                                            border_position = "top";

                                                            hide_frame_for_single_pane = "true";

                                                            mode_normal = "#[bg=blue] ";
                                                            mode_tmux = "#[bg=#ffc387] ";

                                                            tab_normal = "#[fg=#6C7086] {name} ";
                                                            tab_active = "#[fg=#9399B2,bold,italic] {name} ";

                                                            command_git_branch_command = "git rev-parse --abbrev-ref HEAD";
                                                            command_git_branch_format = "#[fg=blue] {stdout} ";
                                                            command_git_branch_interval = "10";
                                                            command_git_branch_rendermode = "static";

                                                            datetime = "#[fg=#6C7086,bold] {format} ";
                                                            datetime_format = "%A, %d %b %Y %H:%M";
                                                            datetime_timezone = "Europe/London";

                                                        }
                                                    ];
                                                };
                                            }
                                        ];
                                    };
                                }

                                # Actual screen
                                # NOTE: We put statusbar on top!

                                { pane = { }; }
                            ];
                        };
                    };
                };
        };
    };

    # Uses `zjstatus` to create a (much nicer!) terminal status bar.
    # NOTE: Sets `__ZELLIJ_DONT_SHOW_STATUS` so that we know not to show it
    # in Starship.
    /*
      xdg.configFile."zellij/layouts/better.kdl".text =
          let
              zjstatus = pkgs.fetchurl {
                  url = "https://github.com/dj95/zjstatus/releases/download/v0.21.0/zjstatus.wasm";
                  hash = "sha256-p6JTnAyim0T3TkJzGhEitzc3JpPovL5k7jb8gv+oLD4=";
              };
          in
          ''
              env {
                  __ZELLIJ_DONT_SHOW_STATUS 0
              }

              layout {
                  pane split_direction="horizontal" {
                      // Statusbar
                      pane size=1 borderless=true {
                          plugin location="file:${zjstatus}" {
                              format_left   "{mode} #[fg=#89B4FA,bold]{session}"
                              format_center "{tabs}"
                              format_right  "{command_git_branch} {datetime}"
                              format_space  ""

                              border_enabled  "false"
                              border_char     "─"
                              border_format   "#[fg=#6C7086]{char}"
                              border_position "top"

                              hide_frame_for_single_pane "true"

                              mode_normal  "#[bg=blue] "
                              mode_tmux    "#[bg=#ffc387] "

                              tab_normal   "#[fg=#6C7086] {name} "
                              tab_active   "#[fg=#9399B2,bold,italic] {name} "

                              command_git_branch_command     "git rev-parse --abbrev-ref HEAD"
                              command_git_branch_format      "#[fg=blue] {stdout} "
                              command_git_branch_interval    "10"
                              command_git_branch_rendermode  "static"

                              datetime        "#[fg=#6C7086,bold] {format} "
                              datetime_format "%A, %d %b %Y %H:%M"
                              datetime_timezone "Europe/Berlin"
                          }
                      }

                      // Actual screen
                      // NOTE: We put statusbar on top!
                      pane
                  }
              }
          '';
    */
}
