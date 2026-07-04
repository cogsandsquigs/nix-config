# Desktop apps commonly used.
{ pkgs, ... }: {
    imports = [ ./browser.nix ];

    home.packages = with pkgs; [
        # Productivity
        discord # currently on macos gets stuck on launch, keeps trying 2 upd (???) ptb and canary don't fix issue
        obsidian
        zoom-us
        qbittorrent

        # Fun
        #spotify
    ];
}
