{pkgs, ...}: {
    imports = [
        ./gpg-agent.nix
    ];

    # MacOS specific-packages
    home.packages = with pkgs; [
        raycast # Spotlight replacement (untill Spotlight recognizes nix packages)
        net-news-wire # RSS reader
        skimpdf # PDF viewer for nvim TODO: Make this multi-platform for nvim use on all devices.
        pinentry_mac # EZ pinentry for GPG
        mkalias
        openssl # TODO: Why?
        whatsapp-for-mac # Whatsapp desktop client
        appcleaner # For cleaning up rogue `.app`s
        # aldente # Battery limiter tool

        # Container utilities (ez docker on macos)
        colima
        lima
        lima-additional-guestagents
    ];
}
