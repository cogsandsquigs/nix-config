{pkgs, ...}: {
  programs.gpg = {
    enable = true;

    settings = {
      use-agent = true;
      no-tty = true;
    };
  };

  programs.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-mac; # TODO: Dynamic based on platform/etc.
  };
}
