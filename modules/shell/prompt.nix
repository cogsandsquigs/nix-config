{
    home = { lib, config, ... }: {
        config = lib.mkIf config.my.user.shell.enable {
            # Like shellInit, but runs last.
            # NOTE: This enables the starship prompt character for transient prompts on fish.
            # See: https://starship.rs/advanced-config/#transientprompt-and-transientrightprompt-in-fish
            programs.fish.shellInitLast = ''
                function starship_transient_prompt_func
                    starship module character
                end
            '';

            programs.starship = {
                enable = true;
                enableBashIntegration = true; # Enable starship in bash
                enableFishIntegration = true;
                enableZshIntegration = true;
                enableTransience = true; # See: https://starship.rs/advanced-config/#transientprompt-and-transientrightprompt-in-fish

                # TODO: try https://starship.rs/presets/catppuccin-powerline
                settings = {
                    add_newline = false;
                    command_timeout = 750; # Number of millis to wait for a command to finish before timing out.

                    # NOTE: $package should come after all language symbols as it displays the package manager + version for the
                    # current language.
                    # NOTE: We need to use `''` in front of any `${<...snip...>}` since that is how nix string interpolation is
                    # escaped. See: https://nix.dev/manual/nix/2.25/language/string-interpolation
                    #
                    # Only what is named here renders: a module left out of `format` is inert however it
                    # is configured, so nothing below configures one that is missing.
                    format = ''
                        [╭─](bright-black) $os$username$hostname$directory$git_branch$git_commit$git_state$git_metrics$git_status$c$cpp$rust$nodejs$bun$python$go$java$kotlin$scala$package$conda$direnv$fill $cmd_duration''${custom.zellij}
                        [╰─](bright-black) $character
                    '';

                    # The prompt used when we write an incomplete statement, i.e. `rm \` or a newline or whatever.
                    continuation_prompt = "[∙](bright-black)";

                    # Character symbol
                    character = {
                        format = "$symbol ";
                        success_symbol = "[⏵](bold green)";
                        error_symbol = "[⏵](bold red)";
                        vimcmd_symbol = "[⏴](bold green)";
                        vimcmd_replace_one_symbol = "[⏴](bold purple)";
                        vimcmd_replace_symbol = "[⏴](bold purple)";
                        vimcmd_visual_symbol = "[⏴](bold yellow)";
                    };

                    # Directory/cwd
                    directory = {
                        format = "[$path]($style)[$read_only]($read_only_style) ";
                        style = "bold bright-cyan";

                        truncation_symbol = "…/";
                        read_only = " ";
                        home_symbol = "~";
                    };

                    # Direnv detection
                    direnv = {
                        disabled = false;
                        format = "[$symbol$allowed$loaded]($style) ";
                        symbol = "direnv ";
                        allowed_msg = "✓";
                        not_allowed_msg = "-";
                        denied_msg = "✗";
                        loaded_msg = "";
                        unloaded_msg = " (!)";
                    };

                    # Conda
                    conda = {
                        disabled = false;
                        symbol = "🅒  ";
                    };

                    # Command duration
                    cmd_duration = {
                        disabled = false;
                        min_time = 500; # in millis
                        format = "took [$duration](bold yellow) in ";
                        style = "bold yellow";
                    };

                    # Filler btwn prompts
                    fill = {
                        symbol = "·";
                        style = "bright-black";
                    };

                    # OS detection and symbols
                    os = {
                        format = "[$symbol]($style)";
                        style = "bold white";
                        disabled = false;

                        # The symbols corresponding to each OS. If the OS is not in this list, it will use
                        # the default symbol.
                        #
                        # NOTE: These require nerd fonts to use!
                        # NOTE: Need spaces since format does not have spaces, and spacing might be different
                        # per-symbol (unicode weirdness).
                        symbols = {
                            Macos = " ";
                            Ubuntu = " ";
                        };
                    };

                    # Hostname detection and symbols
                    hostname = {
                        format = "[$hostname$ssh_symbol]($style) in ";
                        style = "bold green";
                        ssh_only = false;
                        ssh_symbol = " 🛰️ "; # NOTE: space in front to make room btwn it and hostname...
                        disabled = false;
                    };

                    # Username detection and symbols
                    username = {
                        style_root = "bold red";
                        style_user = "bold yellow";
                        detect_env_vars = [ ];
                        format = "[$user]($style)@";
                        show_always = true;
                        disabled = false;
                    };
                    ##########################
                    # LANGUAGES AND PACKAGES #
                    ##########################

                    # C language things
                    c = {
                        symbol = " ";
                        detect_extensions = [
                            "c"
                            "h"
                        ];
                        detect_files = [
                            ".clang-tidy"
                            ".clangd"
                            "compile_commands.json"
                        ];
                    };

                    # C++ language things
                    cpp = {
                        symbol = " ";
                        detect_extensions = [
                            "cpp"
                            "hpp"
                            "cxx"
                            "hxx"
                        ];
                        detect_files = [
                            ".clang-tidy"
                            ".clangd"
                            "compile_commands.json"
                        ];
                    };

                    ###################
                    # CUSTOM COMMANDS #
                    ###################

                    # SSH visibility comes from `hostname.ssh_symbol` above, which `$hostname` renders.
                    custom = {
                        # Zellij integration
                        zellij = {
                            # NOTE: We need to do `\\` so it outputs the string `\(...\)` which then gets interpolated via Starship
                            format = "[Zellij \\($output\\)]($style) ";
                            style = "green bold";
                            description = "Shows the current Zellij monitor you are in";
                            when = "test $ZELLIJ && test ! $__ZELLIJ_DONT_SHOW_STATUS"; # NOTE: `$__ZELLIJ_DONT_SHOW_STATUS` set by layout(s) that show zellij status
                            command = "echo $ZELLIJ_SESSION_NAME";
                            disabled = false;
                        };
                    };
                };
            };
        };
    };
}
