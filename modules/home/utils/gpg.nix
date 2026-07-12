# Shared GPG configuration. The OS-specific pieces — the pinentry program, and
# on macOS the wake-time agent restart — live in the per-OS files.

{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.my.user.utils.enable {
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

      # pinentry.package & the macOS wake-time restart are set per-OS in ./gpg-agent.nix
      # (imported alongside this file).
    };
  };
}
