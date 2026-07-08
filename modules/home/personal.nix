# The full PERSONAL home profile: the shared core (./default.nix) plus games and personal GUI
# apps (Discord, Obsidian, …). Used by the personal machines — the MacBook and the home-desktop
# NixOS tower — via modules/home-manager.nix.
#
# The work machine deliberately does NOT import this; it takes ./default.nix (core) only.
{ ... }: {
    imports = [
        ./default.nix

        ./games.nix
        ./desktop-apps
    ];
}
