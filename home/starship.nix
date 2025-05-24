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
                [╭─](bright-black) $os  ~
                [╰─](bright-black) $character'';

            # Format on right side of prompt
            right_format = '''';

            # The prompt used when we write an incomplete statement, i.e. `rm \` or a newline or whatever.
            continuation_prompt = "[∙](bright-black)";

            # Character symbol
            character = {
                format = "$symbol ";
                success_symbol = "[⏵](bold bright-green)";
                error_symbol = "[⏵](bold bright-red)";
            };

            # OS detection and symbols
            os = {
                format = "[$symbol]($style)";
                style = "bold white";
                disabled = false;

                # The symbols corresponding to each OS. If the OS is not in this list, it will use the default symbol.
                symbols = {
                    Macos = "";
                };
            };
        };
    };
}
