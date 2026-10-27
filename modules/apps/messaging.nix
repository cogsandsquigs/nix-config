{
    flake.modules.homeManager."apps/messaging" = { pkgs, ... }: {
        # On macos, use homebrew for discord / whatsapp
        home.packages =
            with pkgs;
            [ signal-desktop ] ++ (if pkgs.stdenv.hostPlatform.isLinux then [ pkgs.discord ] else [ ]);
    };

    flake.modules.darwin."apps/messaging" = {
        homebrew.casks = [
            "discord"
            "whatsapp"
        ];
    };
}
