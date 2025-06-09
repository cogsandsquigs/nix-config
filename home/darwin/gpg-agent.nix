{pkgs, ...}: {
    # Make sure the mac-specific pinentry is available for GPG agent.
    services.gpg-agent = {
        pinentry.package = pkgs.pinentry_mac;
    };
}
