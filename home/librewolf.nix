{
  programs.librewolf = {
    enable = true;
    settings = {
      "webgl.disabled" = false;

      "identity.fxaccounts.enabled" = false; # Enable/Disable firefox sync

      "privacy.clearOnShutdown.history" = false;
      "privacy.clearOnShutdown.downloads" = true;
      "privacy.resistFingerprinting" = true;
      "privacy.userContext.enabled" = true; # Enable containers
      "privacy.userContext.ui.enabled" = true; # Enable containers UI
    };
  };
}
