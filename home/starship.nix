{...}: {
    programs.starship = {
        enable = true;
        enableFishIntegration = true;

        # Equivalent to writting starship.toml
        # TODO: Use this at some point: https://starship.rs/presets/catppuccin-powerline#catppuccin-powerline-preset
        settings = {
            add_newline = false; # Disable the blank line at the start of the prompt

            # The format of the prompt, which is a string containing the various symbols and styles.
            format = ''
                [╭─](bright-black) $os$directory$git_branch$git_commit$git_state$git_metrics$git_status 
                [╰─](bright-black) $character'';

            # Format on right side of prompt
            right_format = ''took  20s'';

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
                home_symbol = "";
            };

            # Command duration
            cmd_duration = {
                min_time = 500;
                format = "took  [$duration](bold yellow)";
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
                # The file extensions that trigger C language to show up.
                detect_extensions = ["c" "h" "clang-format" "clang-tidy"];
            };
        };
    };
}
