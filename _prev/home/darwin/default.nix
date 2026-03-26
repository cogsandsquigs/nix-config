{ pkgs, ... }:
{
    imports = [ ./gpg-agent.nix ];

    # MacOS specific-packages
    home.packages = with pkgs; [
        pinentry_mac # EZ pinentry for GPG
        mkalias
        openssl # TODO: Why?
        # whatsapp-for-mac # Whatsapp desktop client
        appcleaner # For cleaning up rogue `.app`s
        # aldente # Battery limiter tool

        # Container utilities (ez docker on macos)
        colima
        lima
        lima-additional-guestagents
    ];
}
