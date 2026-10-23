# modules/games/steam.nix
# Steam is system-level (not Home Manager): NixOS needs udev rules + 32-bit graphics, and there is
# no nixpkgs `steam` on darwin, so macOS uses the Homebrew cask via nix-darwin.
{
    flake.modules.nixos."games/steam" = {
        programs.steam = {
            enable = true;
            remotePlay.openFirewall = true;
            localNetworkGameTransfers.openFirewall = true;
        };
    };

    flake.modules.darwin."games/steam" = {
        homebrew = {
            casks = [
                "steam"
                "heroic" # Windows -> Mac games
            ];

            # All 2 below required for heroic winetricks for some reason?
            brews = [
                "zenity"
                "cabextract"
            ];
        };
    };
}
