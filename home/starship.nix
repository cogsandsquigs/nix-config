{...}: {
    programs.starship = {
        enable = true;
        enableFishIntegration = true;

        # Equivalent to writting starship.toml
        # TODO: Use this at some point: https://starship.rs/presets/catppuccin-powerline#catppuccin-powerline-preset
        settings = {
            add_newline = false; # Disable the blank line at the start of the prompt
            format = ''
                [╭─](bright-black) $os  ~
                [╰─](bright-black) $character'';

            # Format on right side of prompt
            right_format = '''';

            # Character symbol
            character = {
                format = "$symbol ";
                success_symbol = "[⏵](bold green)";
                error_symbol = "[⏵](bold red)";
            };

            # OS detection and symbols
            os = {
                disabled = false;
            };
        };
    };
}
