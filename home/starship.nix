{...}: {
    programs.starship = {
        enable = true;
        enableFishIntegration = true;

        # Equivalent to writting starship.toml
        # TODO: Use this at some point: https://starship.rs/presets/catppuccin-powerline#catppuccin-powerline-preset
        settings = {
            format = "$all"; # Default, whatev
            add_newline = false; # Disable the blank line at the start of the prompt
        };
    };
}
