{...}: {
    programs.starship = {
        enable = true;
        enableFishIntegration = true;
        enableTransience = true; # See: https://starship.rs/advanced-config/#transientprompt-and-transientrightprompt-in-fish

        # Equivalent to writting starship.toml
        # TODO: Use this at some point: https://starship.rs/presets/catppuccin-powerline#catppuccin-powerline-preset
        settings = {
            add_newline = false; # Disable the blank line at the start of the prompt
            command_timeout = 750; # Number of millis to wait for a command to finish before timing out.

            # The format of the prompt, which is a string containing the various symbols and styles.
            format = ''
                [╭─](bright-black) $os$directory$git_branch$git_commit$git_state$git_metrics$git_status$c$cpp$rust$nodejs$bun$python$fill $cmd_duration at $time
                [╰─](bright-black) $character
            '';

            # The prompt used when we write an incomplete statement, i.e. `rm \` or a newline or whatever.
            continuation_prompt = "[∙](bright-black)";

            # Character symbol
            character = {
                format = "$symbol ";
                success_symbol = "[⏵](bold bright-green)";
                error_symbol = "[⏵](bold bright-red)";
            };

            # Directory/cwd
            directory = {
                format = "[$path]($style)[$read_only]($read_only_style) ";
                style = "bold bright-cyan";

                ###########
                # SYMBOLS #
                ###########

                truncation_symbol = "…/";
                read_only = "";
                home_symbol = "~";
            };

            # Command duration
            cmd_duration = {
                disabled = false;
                min_time = 500; # in millis
                format = "took [ $duration](bold yellow)";
                style = "bold yellow";
            };

            # Time/terminal clock
            time = {
                disabled = false;
                format = "[ $time]($style) ";
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
                format = "[$symbol]($style)";
                style = "bold white";
                disabled = false;

                # The symbols corresponding to each OS. If the OS is not in this list, it will use the default symbol.
                symbols = {
                    Macos = " ";
                };
            };

            ##########################
            # LANGUAGES AND PACKAGES #
            ##########################

            # C language things
            c = {
                symbol = " ";
                detect_extensions = ["c" "h"];
                detect_files = ["clang-format" "clang-tidy" "compile_commands.json"];
            };

            # C++ language things
            cpp = {
                symbol = " ";
                detect_extensions = ["cpp" "hpp" "cxx" "hxx"];
                detect_files = ["clang-format" "clang-tidy" "compile_commands.json"];
            };
        };
    };
}
