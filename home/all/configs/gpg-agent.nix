{ ... }:
{
    # Make sure the mac-specific pinentry is available for GPG agent.
    services.gpg-agent = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;

        # NOTE: Since pinentry-programs are OS-specific, we set that
        # configuration in `<os-type>/gpg-agent.nix`. See that file for more
        # detail.
    };
}
