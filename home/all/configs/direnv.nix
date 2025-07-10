{
  programs.direnv = {
    enable = true;

    # Enable nix-direnv integration. See:
    # https://github.com/nix-community/nix-direnv
    nix-direnv.enable = true;

    # Integrate with shells
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    # enableFishIntegration = true; # TODO: Why is this read-only?
  };
}
