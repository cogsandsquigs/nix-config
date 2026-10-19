# The macOS desktop.
{
    flake.modules.darwin."sessions/macos" = { pkgs, ... }: {

        # Dock configuration
        system.defaults.dock = {
            autohide = true;
            autohide-delay = 0.0;
            autohide-time-modifier = 0.5;

            persistent-apps = [
                "${pkgs.ghostty-bin}/Applications/Ghostty.app"
                "/System/Applications/System Settings.app"
                "/Applications/Firefox.app"
                "${pkgs.obsidian}/Applications/Obsidian.app" # See apps/obsidian.nix
                "/Applications/Discord.app"
                "/System/Applications/Messages.app"
                "/Applications/WhatsApp.app"
                "/System/Applications/Calendar.app"
                "/System/Applications/Reminders.app"
                "/System/Applications/Photos.app"
            ];
        };
    };

}
