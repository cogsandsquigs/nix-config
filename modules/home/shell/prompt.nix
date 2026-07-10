{ ... }: {
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

        # Equivalent to writting starship.toml
        # TODO: Use this at some point: https://starship.rs/presets/catppuccin-powerline#catppuccin-powerline-preset
        settings = {
            add_newline = false; # Disable the blank line at the start of the prompt
            command_timeout = 750; # Number of millis to wait for a command to finish before timing out.

            # The format of the prompt, which is a string containing the various symbols and styles.
            # NOTE: $package should come after all language symbols as it displays the package manager + version for the
            # current language.
            # NOTE: We need to use `''` in front of any `${<...snip...>}` since that's how nix string interpolation is
            # escaped. See: https://nix.dev/manual/nix/2.25/language/string-interpolation
            format = ''
                [╭─](bright-black) ''${custom.ssh}$username$hostname$os$directory$git_branch$git_commit$git_state$git_metrics$git_status$c$cpp$rust$nodejs$bun$python$go$java$kotlin$scala$package$direnv$fill $cmd_duration$time''${custom.zellij}
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

                ###########
                # SYMBOLS #
                ###########

                truncation_symbol = "…/";
                read_only = " ";
                home_symbol = "~";
            };

            # Direnv detection
            direnv = {
                disabled = false;
            };

            # Command duration
            cmd_duration = {
                disabled = false;
                min_time = 500; # in millis
                format = "took [ $duration](bold yellow) ";
                style = "bold yellow";
            };

            # Time/terminal clock
            time = {
                disabled = false;
                format = "at [ $time]($style) ";
                time_format = "%I:%M:%S %P";
                style = "bold purple";
            };

            # Filler btwn prompts
            fill = {
                symbol = "·";
                style = "bright-black";
            };

            # OS detection and symbols
            os = {
                format = "[$symbol]($style) in "; # See `settings.hostname`
                style = "bold white";
                disabled = false;

                # The symbols corresponding to each OS. If the OS is not in this list, it will use
                # the default symbol.
                #
                # NOTE: These require nerd fonts to use!
                symbols = {
                    Macos = ""; # No space since MacOS symbol works... # TODO: Replace w/ nerd fonts one when supported...
                    Ubuntu = "";
                };
            };

            # Hostname detection and symbols
            hostname = {
                # NOTE: Disabling the ssh symbol since I have my own command to do so because I want
                # SSH to display before the user. See `settings.custom.ssh`.
                #format = "[$ssh_symbol$hostname]($style) in ";
                format = "[$hostname]($style) "; # NOTE: No "in" since $os comes after, see `settings.os`
                style = "bold green";
                ssh_only = false;
                ssh_symbol = "🌐 ";
                disabled = false;
                aliases = { }; # TODO: make module accessing all info (?) of all machines, put aliases for certain machines here.
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

            custom = {
                # SSH checking, apart from hostname since we want ssh visibility BEFORE username AND
                # hostname
                ssh = {
                    when = "test $SSH_TTY || test $SSH_CONNECTION || test $SSH_CLIENT";
                    format = "🌐 ";
                    description = "Displays if you're currently in an SSH session.";
                    disabled = false;
                };

                # Zellij integration
                zellij = {
                    # NOTE: We need to do `\\` so it outputs the string `\(...\)` which then gets interpolated via Starship
                    format = "in [Zellij \\($output\\)]($style) ";
                    style = "green bold";
                    description = "Shows the current Zellij monitor you are in";
                    when = "test $ZELLIJ && test ! $__ZELLIJ_DONT_SHOW_STATUS"; # NOTE: `$__ZELLIJ_DONT_SHOW_STATUS` set by layout(s) that show zellij status
                    command = "echo $ZELLIJ_SESSION_NAME";
                };
            };
        };
    };
}
