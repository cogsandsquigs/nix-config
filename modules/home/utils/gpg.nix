# Shared GPG configuration. The OS-specific pieces — the pinentry program, and
# on macOS the wake-time agent restart — live in the per-OS files.

{ pkgs, ... }: {
    home.packages = with pkgs; [ gnupg ];

    programs.gpg = {
        enable = true;

        settings = {
            use-agent = true;
            no-tty = true;
        };
    };

    services.gpg-agent = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;

        # pinentry.package & OS-specific gpg-agent config is set per-OS in
        # ../../system/{darwin,nixos}/gpg-agent.nix.
    };
}
